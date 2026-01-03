import Foundation
import ScreenCaptureKit
import AVFoundation

@MainActor
final class ScreenRecorder: NSObject, ObservableObject {
    private var stream: SCStream?
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?

    private var outputURL: URL?
    private var isRecording = false
    private var startTime: CMTime?

    private let videoQueue = DispatchQueue(label: "com.animamac.videoqueue", qos: .userInteractive)

    // MARK: - Content Discovery

    static func availableContent() async throws -> SCShareableContent {
        try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
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
                AVVideoAverageBitRateKey: 10_000_000,
                AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
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
            throw RecordingError.recordingFailed("No active recording")
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
            throw RecordingError.recordingFailed("No output URL")
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

        // Use Task to access main actor-isolated properties
        Task { @MainActor in
            guard let videoInput = videoInput, videoInput.isReadyForMoreMediaData else { return }
            
            // Calculate relative time
            if startTime == nil {
                startTime = presentationTime
            }

            let relativeTime = CMTimeSubtract(presentationTime, startTime!)

            // Append pixel buffer
            pixelBufferAdaptor?.append(imageBuffer, withPresentationTime: relativeTime)
        }
    }
}
