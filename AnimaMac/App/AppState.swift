import SwiftUI
import ScreenCaptureKit
import AppKit

@MainActor
final class AppState: ObservableObject {
    // MARK: - Recording State
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var isPreparing = false

    // MARK: - Selection State
    @Published var isSelectingArea = false
    @Published var isSelectingWindow = false
    @Published var selectedRect: CGRect?
    @Published var selectedWindow: SCWindow?
    @Published var selectedDisplay: SCDisplay?

    // MARK: - Export State
    @Published var isExporting = false
    @Published var exportProgress: Double = 0

    // MARK: - Library
    @Published var recordings: [Recording] = []
    @Published var selectedRecording: Recording?

    // MARK: - Settings
    @Published var captureConfiguration = CaptureConfiguration()
    @Published var exportSettings = ExportSettings()

    // MARK: - Errors
    @Published var lastError: Error?
    @Published var showingError = false

    // MARK: - Components
    private(set) var screenRecorder: ScreenRecorder?
    private(set) var gifExporter: GIFExporter?
    private(set) var recordingLibrary: RecordingLibrary?
    private var overlayController: OverlayWindowController?

    private var recordingTimer: Timer?

    init() {
        Task {
            await setupComponents()
        }
    }

    private func setupComponents() async {
        recordingLibrary = RecordingLibrary()
        gifExporter = GIFExporter()
        screenRecorder = ScreenRecorder()
        overlayController = OverlayWindowController()

        // Load existing recordings
        if let library = recordingLibrary {
            recordings = library.loadRecordings()
        }
    }

    // MARK: - Recording Control

    func startAreaSelection() {
        isSelectingArea = true
        isSelectingWindow = false

        Task {
            await showAreaSelectionOverlay()
        }
    }

    private func showAreaSelectionOverlay() async {
        // Get the main display
        guard let display = try? await ScreenRecorder.availableDisplays().first else {
            print("No displays available")
            cancelSelection()
            return
        }

        selectedDisplay = display

        overlayController?.showOverlay(
            for: display,
            onComplete: { [weak self] rect, display in
                guard let self else { return }
                self.selectedRect = rect
                self.selectedDisplay = display
                self.isSelectingArea = false

                Task {
                    do {
                        try await self.startRecording()
                    } catch {
                        print("Failed to start recording: \(error)")
                        self.lastError = error
                        self.showingError = true
                    }
                }
            },
            onCancel: { [weak self] in
                self?.cancelSelection()
            }
        )
    }

    func startWindowSelection() {
        isSelectingWindow = true
        isSelectingArea = false

        Task {
            await showWindowPicker()
        }
    }

    private func showWindowPicker() async {
        do {
            let windows = try await ScreenRecorder.availableWindows()
            if windows.isEmpty {
                print("No windows available")
                cancelSelection()
                return
            }

            // Show window picker panel
            await MainActor.run {
                let panel = NSPanel(
                    contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
                    styleMask: [.titled, .closable, .resizable],
                    backing: .buffered,
                    defer: false
                )
                panel.title = "Select Window to Record"
                panel.center()

                let pickerView = WindowPickerView()
                    .environmentObject(self)

                panel.contentView = NSHostingView(rootView: pickerView)
                panel.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        } catch {
            print("Failed to get windows: \(error)")
            cancelSelection()
        }
    }

    func cancelSelection() {
        isSelectingArea = false
        isSelectingWindow = false
        selectedRect = nil
        selectedWindow = nil
    }

    func startRecording() async throws {
        guard let recorder = screenRecorder else { return }

        isPreparing = true
        defer { isPreparing = false }

        let outputURL = FileManager.animaMacRecordingsDirectory
            .appendingPathComponent("\(Date().ISO8601Format()).mov")

        if let window = selectedWindow {
            try await recorder.startRecording(
                window: window,
                configuration: captureConfiguration,
                outputURL: outputURL
            )
        } else if let rect = selectedRect, let display = selectedDisplay {
            try await recorder.startRecording(
                display: display,
                cropRect: rect,
                configuration: captureConfiguration,
                outputURL: outputURL
            )
        } else if let display = selectedDisplay {
            try await recorder.startRecording(
                display: display,
                cropRect: nil,
                configuration: captureConfiguration,
                outputURL: outputURL
            )
        } else {
            throw RecordingError.noContentSelected
        }

        isRecording = true
        recordingDuration = 0
        startRecordingTimer()

        // Clear selection state
        isSelectingArea = false
        isSelectingWindow = false
    }

    func stopRecording() async throws {
        guard let recorder = screenRecorder else { return }

        stopRecordingTimer()

        let outputURL = try await recorder.stopRecording()
        isRecording = false

        // Create recording entry
        let recording = Recording(
            id: UUID(),
            createdAt: Date(),
            sourceVideoURL: outputURL,
            duration: recordingDuration
        )

        // Save to library
        recordingLibrary?.save(recording)
        recordings.insert(recording, at: 0)

        // Auto-export to GIF
        await exportToGIF(recording: recording)
    }

    private func exportToGIF(recording: Recording) async {
        guard let exporter = gifExporter else { return }

        isExporting = true
        exportProgress = 0

        do {
            let gifURL = recording.sourceVideoURL
                .deletingPathExtension()
                .appendingPathExtension("gif")

            try await exporter.export(
                videoURL: recording.sourceVideoURL,
                to: gifURL,
                settings: exportSettings
            ) { [weak self] progress in
                Task { @MainActor in
                    self?.exportProgress = progress
                }
            }

            // Update recording with GIF path
            var updatedRecording = recording
            updatedRecording.exportedGIFURL = gifURL
            recordingLibrary?.update(updatedRecording)

            if let index = recordings.firstIndex(where: { $0.id == recording.id }) {
                recordings[index] = updatedRecording
            }

            // Copy to clipboard
            copyToClipboard(gifURL)

        } catch {
            lastError = error
            showingError = true
        }

        isExporting = false
    }

    private func copyToClipboard(_ url: URL) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(try? Data(contentsOf: url), forType: .fileContents)
        pasteboard.writeObjects([url as NSURL])
    }

    // MARK: - Timer

    private func startRecordingTimer() {
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.recordingDuration += 0.1
            }
        }
    }

    private func stopRecordingTimer() {
        recordingTimer?.invalidate()
        recordingTimer = nil
    }

    // MARK: - Library Management

    func deleteRecording(_ recording: Recording) {
        recordingLibrary?.delete(recording)
        recordings.removeAll { $0.id == recording.id }
    }

    func revealInFinder(_ recording: Recording) {
        let url = recording.exportedGIFURL ?? recording.sourceVideoURL
        NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: "")
    }
}

// MARK: - Errors

enum RecordingError: LocalizedError {
    case noContentSelected
    case permissionDenied
    case recordingFailed(String)
    case noActiveRecording
    case outputURLNotSet

    var errorDescription: String? {
        switch self {
        case .noContentSelected:
            return "No screen area or window selected"
        case .permissionDenied:
            return "Screen recording permission denied"
        case .recordingFailed(let reason):
            return "Recording failed: \(reason)"
        case .noActiveRecording:
            return "No active recording to stop"
        case .outputURLNotSet:
            return "Output URL not configured"
        }
    }
}
