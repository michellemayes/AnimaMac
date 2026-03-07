import Foundation
import ScreenCaptureKit
import AVFoundation
import CoreGraphics

// MARK: - Protocol

protocol ScreenRecorderProtocol: AnyObject {
    func startRecording(
        display: SCDisplay,
        cropRect: CGRect?,
        configuration: CaptureConfiguration,
        outputURL: URL
    ) async throws

    func startRecording(
        window: SCWindow,
        configuration: CaptureConfiguration,
        outputURL: URL
    ) async throws

    func stopRecording() async throws -> URL
}

// MARK: - Implementation

final class ScreenRecorder: NSObject, ObservableObject, ScreenRecorderProtocol {
    private var stream: SCStream?
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?

    private var outputURL: URL?
    private var isRecording = false
    private var startTime: CMTime?
    private var frameCount: Int = 0

    // Use a dedicated serial queue for video writing to avoid frame drops
    private let videoQueue = DispatchQueue(label: "com.animamac.videoqueue", qos: .userInteractive)

    // Lock for thread-safe access to writer components
    private let writerLock = NSLock()

    // MARK: - Permissions

    /// Check if screen recording permission has been granted
    static var hasScreenRecordingPermission: Bool {
        CGPreflightScreenCaptureAccess()
    }

    /// Request screen recording permission. Returns true if granted.
    @discardableResult
    static func requestScreenRecordingPermission() -> Bool {
        CGRequestScreenCaptureAccess()
    }

    /// Ensure we have permission, requesting if needed. Throws if denied.
    static func ensurePermission() async throws {
        if hasScreenRecordingPermission {
            return
        }

        // Request permission - this will show the system dialog
        let granted = requestScreenRecordingPermission()

        if !granted {
            // Give the user a moment to respond to the dialog
            // The first request always returns false even if user clicks "allow"
            // We need to wait and check again
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            // Check again after potential user interaction
            if !hasScreenRecordingPermission {
                throw ScreenRecorderError.permissionDenied
            }
        }
    }

    // MARK: - Content Discovery

    static func availableContent() async throws -> SCShareableContent {
        // Check permission first
        try await ensurePermission()
        return try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
    }

    static func availableDisplays() async throws -> [SCDisplay] {
        try await availableContent().displays
    }

    static func availableWindows() async throws -> [SCWindow] {
        try await availableContent().windows.filter { window in
            // Filter out system windows and empty titles
            guard let title = window.title, !title.isEmpty else { return false }
            guard let app = window.owningApplication else { return false }
            guard app.bundleIdentifier != Bundle.main.bundleIdentifier else { return false }
            return true
        }
    }

    // MARK: - Recording Control

    func startRecording(
        display: SCDisplay,
        cropRect: CGRect?,
        configuration: CaptureConfiguration,
        outputURL: URL
    ) async throws {
        let filter = SCContentFilter(display: display, excludingWindows: [])

        let streamConfig = SCStreamConfiguration()
        configuration.applyTo(streamConfig, for: display)

        if let cropRect = cropRect {
            streamConfig.sourceRect = cropRect
            streamConfig.width = Int(cropRect.width * configuration.quality.scaleFactor)
            streamConfig.height = Int(cropRect.height * configuration.quality.scaleFactor)
        }

        try await startCapture(filter: filter, configuration: streamConfig, outputURL: outputURL)
    }

    func startRecording(
        window: SCWindow,
        configuration: CaptureConfiguration,
        outputURL: URL
    ) async throws {
        let filter = SCContentFilter(desktopIndependentWindow: window)

        let streamConfig = SCStreamConfiguration()
        configuration.applyTo(streamConfig, for: window)

        try await startCapture(filter: filter, configuration: streamConfig, outputURL: outputURL)
    }

    private func startCapture(
        filter: SCContentFilter,
        configuration: SCStreamConfiguration,
        outputURL: URL
    ) async throws {
        self.outputURL = outputURL

        // Ensure directory exists
        try FileManager.default.createDirectory(
            at: outputURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        // Setup asset writer
        assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mov)

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: configuration.width,
            AVVideoHeightKey: configuration.height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: 20_000_000,  // Higher bitrate for better quality
                AVVideoMaxKeyFrameIntervalKey: 30,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                AVVideoAllowFrameReorderingKey: false  // Reduce latency
            ]
        ]

        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput?.expectsMediaDataInRealTime = true

        let sourcePixelBufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: configuration.width,
            kCVPixelBufferHeightKey as String: configuration.height
        ]

        pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoInput!,
            sourcePixelBufferAttributes: sourcePixelBufferAttributes
        )

        if assetWriter!.canAdd(videoInput!) {
            assetWriter!.add(videoInput!)
        }

        assetWriter!.startWriting()
        assetWriter!.startSession(atSourceTime: .zero)

        // Create and start stream
        stream = SCStream(filter: filter, configuration: configuration, delegate: self)

        try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: videoQueue)
        try await stream?.startCapture()

        isRecording = true
        startTime = nil
    }

    func stopRecording() async throws -> URL {
        guard isRecording, let stream = stream else {
            throw RecordingError.noActiveRecording
        }

        try await stream.stopCapture()
        self.stream = nil
        isRecording = false

        // Finalize video
        videoInput?.markAsFinished()

        await withCheckedContinuation { continuation in
            assetWriter?.finishWriting {
                continuation.resume()
            }
        }

        guard let url = outputURL else {
            throw RecordingError.outputURLNotSet
        }

        // Clean up
        assetWriter = nil
        videoInput = nil
        pixelBufferAdaptor = nil
        outputURL = nil
        startTime = nil

        return url
    }
}

// MARK: - SCStreamDelegate

extension ScreenRecorder: SCStreamDelegate {
    nonisolated func stream(_ stream: SCStream, didStopWithError error: Error) {
        Task { @MainActor in
            print("Stream stopped with error: \(error)")
        }
    }
}

// MARK: - SCStreamOutput

extension ScreenRecorder: SCStreamOutput {
    nonisolated func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of type: SCStreamOutputType
    ) {
        guard type == .screen else { return }
        guard let imageBuffer = sampleBuffer.imageBuffer else { return }

        let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        // Access shared state through MainActor synchronously to avoid frame drops
        // We need to capture the writer components safely
        var localVideoInput: AVAssetWriterInput?
        var localAdaptor: AVAssetWriterInputPixelBufferAdaptor?
        var localStartTime: CMTime?
        var needsStartTime = false

        // Synchronously access main actor state
        DispatchQueue.main.sync {
            localVideoInput = self.videoInput
            localAdaptor = self.pixelBufferAdaptor
            localStartTime = self.startTime
            needsStartTime = self.startTime == nil

            if needsStartTime {
                self.startTime = presentationTime
                localStartTime = presentationTime
            }
        }

        guard let videoInput = localVideoInput,
              let adaptor = localAdaptor,
              let start = localStartTime,
              videoInput.isReadyForMoreMediaData else {
            return
        }

        let relativeTime = CMTimeSubtract(presentationTime, start)

        // Append pixel buffer on the video queue (we're already on it)
        adaptor.append(imageBuffer, withPresentationTime: relativeTime)
    }
}

// MARK: - Errors

enum ScreenRecorderError: LocalizedError {
    case permissionDenied
    case noDisplaysAvailable

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Screen recording permission was denied. Please enable it in System Settings > Privacy & Security > Screen Recording."
        case .noDisplaysAvailable:
            return "No displays available for recording."
        }
    }
}
