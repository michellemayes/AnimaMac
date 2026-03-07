import Foundation
import ScreenCaptureKit
import Testing
@testable import AnimaMacCore

@Suite("AppState")
@MainActor
struct AppStateTests {

    private func makeAppState() -> (AppState, MockScreenRecorder, MockGIFExporter, MockRecordingLibrary) {
        let recorder = MockScreenRecorder()
        let exporter = MockGIFExporter()
        let library = MockRecordingLibrary()
        let state = AppState(
            screenRecorder: recorder,
            gifExporter: exporter,
            recordingLibrary: library
        )
        return (state, recorder, exporter, library)
    }

    // MARK: - Initial State

    @Test("Initial state is correct")
    func initialState() {
        let (state, _, _, _) = makeAppState()
        #expect(!state.isRecording)
        #expect(state.recordingDuration == 0)
        #expect(!state.isPreparing)
        #expect(!state.isSelectingArea)
        #expect(!state.isSelectingWindow)
        #expect(state.selectedRect == nil)
        #expect(state.selectedWindow == nil)
        #expect(state.selectedDisplay == nil)
        #expect(!state.isExporting)
        #expect(state.exportProgress == 0)
        #expect(state.lastError == nil)
        #expect(!state.showingError)
    }

    @Test("Init with library loads recordings")
    func initLoadsRecordings() {
        let recorder = MockScreenRecorder()
        let exporter = MockGIFExporter()
        let library = MockRecordingLibrary()
        let recording = Recording(id: UUID(), createdAt: Date(), sourceVideoURL: URL(fileURLWithPath: "/tmp/test.mov"), duration: 10.0)
        library.recordings = [recording]

        let state = AppState(screenRecorder: recorder, gifExporter: exporter, recordingLibrary: library)
        #expect(state.recordings.count == 1)
        #expect(state.recordings.first?.id == recording.id)
    }

    // MARK: - Selection

    @Test("Start area selection")
    func startAreaSelection() {
        let (state, _, _, _) = makeAppState()
        state.startAreaSelection()
        #expect(state.isSelectingArea)
        #expect(!state.isSelectingWindow)
    }

    @Test("Start window selection")
    func startWindowSelection() {
        let (state, _, _, _) = makeAppState()
        state.startWindowSelection()
        #expect(state.isSelectingWindow)
        #expect(!state.isSelectingArea)
    }

    @Test("Cancel selection clears state")
    func cancelSelection() {
        let (state, _, _, _) = makeAppState()
        state.isSelectingArea = true
        state.isSelectingWindow = true
        state.selectedRect = CGRect(x: 0, y: 0, width: 100, height: 100)

        state.cancelSelection()

        #expect(!state.isSelectingArea)
        #expect(!state.isSelectingWindow)
        #expect(state.selectedRect == nil)
        #expect(state.selectedWindow == nil)
    }

    @Test("Area selection clears window selection")
    func areaSelectionClearsWindow() {
        let (state, _, _, _) = makeAppState()
        state.isSelectingWindow = true
        state.startAreaSelection()
        #expect(state.isSelectingArea)
        #expect(!state.isSelectingWindow)
    }

    @Test("Window selection clears area selection")
    func windowSelectionClearsArea() {
        let (state, _, _, _) = makeAppState()
        state.isSelectingArea = true
        state.startWindowSelection()
        #expect(state.isSelectingWindow)
        #expect(!state.isSelectingArea)
    }

    // MARK: - Recording

    @Test("Start recording with no content throws")
    func startRecordingNoContent() async {
        let (state, _, _, _) = makeAppState()
        await #expect(throws: RecordingError.self) {
            try await state.startRecording()
        }
    }

    @Test("Stop recording saves to library")
    func stopRecordingSaves() async throws {
        let (state, recorder, _, library) = makeAppState()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_\(UUID()).mov")
        try Data("test".utf8).write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        recorder.outputURL = tempURL
        state.isRecording = true
        state.recordingDuration = 5.0

        try await state.stopRecording()

        #expect(!state.isRecording)
        #expect(library.saveCalled)
        #expect(state.recordings.count == 1)
    }

    @Test("New recording inserted at beginning")
    func recordingInsertedAtBeginning() async throws {
        let (state, recorder, _, _) = makeAppState()
        let existing = Recording(id: UUID(), createdAt: Date().addingTimeInterval(-3600), sourceVideoURL: URL(fileURLWithPath: "/tmp/old.mov"), duration: 5.0)
        state.recordings = [existing]

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_\(UUID()).mov")
        try Data("test".utf8).write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        recorder.outputURL = tempURL
        state.isRecording = true
        state.recordingDuration = 3.0

        try await state.stopRecording()

        #expect(state.recordings.count == 2)
        #expect(state.recordings[0].duration == 3.0)
        #expect(state.recordings[1].id == existing.id)
    }

    // MARK: - Library Management

    @Test("Delete recording removes from list")
    func deleteRecording() {
        let (state, _, _, library) = makeAppState()
        let recording = Recording(id: UUID(), createdAt: Date(), sourceVideoURL: URL(fileURLWithPath: "/tmp/test.mov"), duration: 10.0)
        state.recordings = [recording]

        state.deleteRecording(recording)

        #expect(library.deleteCalled)
        #expect(state.recordings.isEmpty)
    }

    @Test("Delete specific recording keeps others")
    func deleteSpecificRecording() {
        let (state, _, _, _) = makeAppState()
        let r1 = Recording(id: UUID(), createdAt: Date(), sourceVideoURL: URL(fileURLWithPath: "/tmp/test1.mov"), duration: 10.0)
        let r2 = Recording(id: UUID(), createdAt: Date(), sourceVideoURL: URL(fileURLWithPath: "/tmp/test2.mov"), duration: 15.0)
        state.recordings = [r1, r2]

        state.deleteRecording(r1)

        #expect(state.recordings.count == 1)
        #expect(state.recordings[0].id == r2.id)
    }

    // MARK: - Settings

    @Test("Default capture configuration")
    func defaultCaptureConfig() {
        let (state, _, _, _) = makeAppState()
        #expect(state.captureConfiguration.framesPerSecond == 30)
        #expect(state.captureConfiguration.showsCursor)
        #expect(state.captureConfiguration.quality == .high)
    }

    @Test("Default export settings")
    func defaultExportSettings() {
        let (state, _, _, _) = makeAppState()
        #expect(state.exportSettings.preset == .medium)
        #expect(state.exportSettings.loopCount == 0)
    }

    @Test("Capture configuration mutation")
    func captureConfigMutation() {
        let (state, _, _, _) = makeAppState()
        state.captureConfiguration.framesPerSecond = 60
        state.captureConfiguration.showsCursor = false
        state.captureConfiguration.quality = .low
        state.captureConfiguration.capturesMouseClicks = true

        #expect(state.captureConfiguration.framesPerSecond == 60)
        #expect(!state.captureConfiguration.showsCursor)
        #expect(state.captureConfiguration.quality == .low)
        #expect(state.captureConfiguration.capturesMouseClicks)
    }

    @Test("Export settings mutation")
    func exportSettingsMutation() {
        let (state, _, _, _) = makeAppState()
        state.exportSettings.preset = .small
        state.exportSettings.loopCount = 3

        #expect(state.exportSettings.preset == .small)
        #expect(state.exportSettings.loopCount == 3)
        #expect(state.exportSettings.fps == 10)
    }

    // MARK: - Error State

    @Test("Error state can be set and cleared")
    func errorState() {
        let (state, _, _, _) = makeAppState()
        state.lastError = RecordingError.permissionDenied
        state.showingError = true

        #expect(state.showingError)
        #expect(state.lastError != nil)

        state.lastError = nil
        state.showingError = false

        #expect(state.lastError == nil)
        #expect(!state.showingError)
    }

    // MARK: - Export State

    @Test("Export progress can be updated")
    func exportProgress() {
        let (state, _, _, _) = makeAppState()
        state.isExporting = true
        state.exportProgress = 0.5

        #expect(state.isExporting)
        #expect(state.exportProgress == 0.5)
    }

    // MARK: - Selected Recording

    @Test("Selected recording initially nil")
    func selectedRecordingNil() {
        let (state, _, _, _) = makeAppState()
        #expect(state.selectedRecording == nil)
    }

    @Test("Selected recording can be set")
    func selectedRecordingSet() {
        let (state, _, _, _) = makeAppState()
        let recording = Recording(id: UUID(), createdAt: Date(), sourceVideoURL: URL(fileURLWithPath: "/tmp/test.mov"), duration: 10.0)
        state.selectedRecording = recording
        #expect(state.selectedRecording?.id == recording.id)
    }
}

// MARK: - Mocks

@MainActor
class MockScreenRecorder: ScreenRecorderProtocol, @unchecked Sendable {
    var startRecordingCalled = false
    var stopRecordingCalled = false
    var outputURL: URL?
    var shouldThrowError = false

    func startRecording(display: SCDisplay, cropRect: CGRect?, configuration: CaptureConfiguration, outputURL: URL) async throws {
        if shouldThrowError { throw RecordingError.recordingFailed("Mock error") }
        startRecordingCalled = true
        self.outputURL = outputURL
    }

    func startRecording(window: SCWindow, configuration: CaptureConfiguration, outputURL: URL) async throws {
        if shouldThrowError { throw RecordingError.recordingFailed("Mock error") }
        startRecordingCalled = true
        self.outputURL = outputURL
    }

    func stopRecording() async throws -> URL {
        stopRecordingCalled = true
        guard let url = outputURL else { throw RecordingError.outputURLNotSet }
        return url
    }
}

@MainActor
class MockGIFExporter: GIFExporterProtocol, @unchecked Sendable {
    var exportCalled = false
    var shouldThrowError = false

    func export(videoURL: URL, to outputURL: URL, settings: ExportSettings, progressHandler: @escaping @Sendable (Double) -> Void) async throws {
        if shouldThrowError { throw FFmpegError.executionFailed("Mock error") }
        exportCalled = true
        progressHandler(0.5)
        progressHandler(1.0)
    }

    func buildFilterChain(settings: ExportSettings) -> String {
        "[0:v]fps=\(settings.fps),scale=\(settings.maxWidth):-2:flags=lanczos"
    }
}

class MockRecordingLibrary: RecordingLibraryProtocol {
    var recordings: [Recording] = []
    var saveCalled = false
    var updateCalled = false
    var deleteCalled = false
    var deleteAllCalled = false

    func loadRecordings() -> [Recording] { recordings }
    func save(_ recording: Recording) { saveCalled = true; recordings.insert(recording, at: 0) }
    func update(_ recording: Recording) {
        updateCalled = true
        if let i = recordings.firstIndex(where: { $0.id == recording.id }) { recordings[i] = recording }
    }
    func delete(_ recording: Recording) { deleteCalled = true; recordings.removeAll { $0.id == recording.id } }
    func deleteAll() { deleteAllCalled = true; recordings.removeAll() }
    var totalStorageUsed: Int64 { 0 }
    var formattedStorageUsed: String { "0 MB" }
}
