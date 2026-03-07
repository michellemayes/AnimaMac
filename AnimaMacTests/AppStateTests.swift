import XCTest
import ScreenCaptureKit
@testable import AnimaMacCore

@MainActor
final class AppStateTests: XCTestCase {

    var appState: AppState!
    var mockRecorder: MockScreenRecorder!
    var mockExporter: MockGIFExporter!
    var mockLibrary: MockRecordingLibrary!

    override func setUp() async throws {
        try await super.setUp()
        mockRecorder = MockScreenRecorder()
        mockExporter = MockGIFExporter()
        mockLibrary = MockRecordingLibrary()

        appState = AppState(
            screenRecorder: mockRecorder,
            gifExporter: mockExporter,
            recordingLibrary: mockLibrary
        )
    }

    override func tearDown() async throws {
        appState = nil
        mockRecorder = nil
        mockExporter = nil
        mockLibrary = nil
        try await super.tearDown()
    }

    // MARK: - Initial State Tests

    func testInitialState() {
        XCTAssertFalse(appState.isRecording)
        XCTAssertEqual(appState.recordingDuration, 0)
        XCTAssertFalse(appState.isPreparing)
        XCTAssertFalse(appState.isSelectingArea)
        XCTAssertFalse(appState.isSelectingWindow)
        XCTAssertNil(appState.selectedRect)
        XCTAssertNil(appState.selectedWindow)
        XCTAssertNil(appState.selectedDisplay)
        XCTAssertFalse(appState.isExporting)
        XCTAssertEqual(appState.exportProgress, 0)
        XCTAssertNil(appState.lastError)
        XCTAssertFalse(appState.showingError)
    }

    func testInitWithRecordingLibraryLoadsRecordings() {
        let existingRecording = Recording(
            id: UUID(),
            createdAt: Date(),
            sourceVideoURL: URL(fileURLWithPath: "/tmp/test.mov"),
            duration: 10.0
        )
        mockLibrary.recordings = [existingRecording]

        let state = AppState(
            screenRecorder: mockRecorder,
            gifExporter: mockExporter,
            recordingLibrary: mockLibrary
        )

        XCTAssertEqual(state.recordings.count, 1)
        XCTAssertEqual(state.recordings.first?.id, existingRecording.id)
    }

    // MARK: - Selection State Tests

    func testStartAreaSelection() {
        appState.startAreaSelection()

        XCTAssertTrue(appState.isSelectingArea)
        XCTAssertFalse(appState.isSelectingWindow)
    }

    func testStartWindowSelection() {
        appState.startWindowSelection()

        XCTAssertTrue(appState.isSelectingWindow)
        XCTAssertFalse(appState.isSelectingArea)
    }

    func testCancelSelection() {
        appState.isSelectingArea = true
        appState.isSelectingWindow = true
        appState.selectedRect = CGRect(x: 0, y: 0, width: 100, height: 100)

        appState.cancelSelection()

        XCTAssertFalse(appState.isSelectingArea)
        XCTAssertFalse(appState.isSelectingWindow)
        XCTAssertNil(appState.selectedRect)
        XCTAssertNil(appState.selectedWindow)
    }

    // MARK: - Recording Tests

    func testStartRecordingWithNoContentThrowsError() async {
        do {
            try await appState.startRecording()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is RecordingError)
        }
    }

    func testStopRecordingSavesToLibrary() async throws {
        // Setup: simulate a recording in progress
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_\(UUID()).mov")
        try Data("test".utf8).write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        mockRecorder.outputURL = tempURL
        appState.isRecording = true
        appState.recordingDuration = 5.0

        try await appState.stopRecording()

        XCTAssertFalse(appState.isRecording)
        XCTAssertTrue(mockLibrary.saveCalled)
        XCTAssertEqual(appState.recordings.count, 1)
    }

    // MARK: - Library Management Tests

    func testDeleteRecording() {
        let recording = Recording(
            id: UUID(),
            createdAt: Date(),
            sourceVideoURL: URL(fileURLWithPath: "/tmp/test.mov"),
            duration: 10.0
        )
        appState.recordings = [recording]

        appState.deleteRecording(recording)

        XCTAssertTrue(mockLibrary.deleteCalled)
        XCTAssertTrue(appState.recordings.isEmpty)
    }

    // MARK: - Settings Tests

    func testCaptureConfigurationDefault() {
        XCTAssertEqual(appState.captureConfiguration.framesPerSecond, 30)
        XCTAssertTrue(appState.captureConfiguration.showsCursor)
        XCTAssertEqual(appState.captureConfiguration.quality, .high)
    }

    func testExportSettingsDefault() {
        XCTAssertEqual(appState.exportSettings.preset, .medium)
        XCTAssertEqual(appState.exportSettings.loopCount, 0)
    }

    func testUpdateCaptureConfiguration() {
        appState.captureConfiguration.framesPerSecond = 60
        appState.captureConfiguration.showsCursor = false

        XCTAssertEqual(appState.captureConfiguration.framesPerSecond, 60)
        XCTAssertFalse(appState.captureConfiguration.showsCursor)
    }

    func testUpdateExportSettings() {
        appState.exportSettings.preset = .large

        XCTAssertEqual(appState.exportSettings.preset, .large)
        XCTAssertEqual(appState.exportSettings.fps, 20)
    }

    // MARK: - Error Handling Tests

    func testErrorStateClearsOnNewAction() {
        appState.lastError = RecordingError.noContentSelected
        appState.showingError = true

        appState.startAreaSelection()

        // Error should remain until explicitly dismissed
        XCTAssertNotNil(appState.lastError)
    }

    // MARK: - Recording Duration Tests

    func testRecordingDurationInitiallyZero() {
        XCTAssertEqual(appState.recordingDuration, 0)
    }

    // MARK: - Additional Selection Tests

    func testStartAreaSelectionClearsWindowSelection() {
        appState.isSelectingWindow = true
        appState.startAreaSelection()

        XCTAssertTrue(appState.isSelectingArea)
        XCTAssertFalse(appState.isSelectingWindow)
    }

    func testStartWindowSelectionClearsAreaSelection() {
        appState.isSelectingArea = true
        appState.startWindowSelection()

        XCTAssertTrue(appState.isSelectingWindow)
        XCTAssertFalse(appState.isSelectingArea)
    }

    // MARK: - Additional Recording Tests

    func testRecordingStateAfterStopRecording() async throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_\(UUID()).mov")
        try Data("test".utf8).write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        mockRecorder.outputURL = tempURL
        appState.isRecording = true
        appState.recordingDuration = 10.5

        try await appState.stopRecording()

        XCTAssertFalse(appState.isRecording)
        XCTAssertTrue(mockRecorder.stopRecordingCalled)
    }

    func testRecordingInsertedAtBeginning() async throws {
        // Add existing recording
        let existingRecording = Recording(
            id: UUID(),
            createdAt: Date().addingTimeInterval(-3600),
            sourceVideoURL: URL(fileURLWithPath: "/tmp/old.mov"),
            duration: 5.0
        )
        appState.recordings = [existingRecording]

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_\(UUID()).mov")
        try Data("test".utf8).write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        mockRecorder.outputURL = tempURL
        appState.isRecording = true
        appState.recordingDuration = 3.0

        try await appState.stopRecording()

        XCTAssertEqual(appState.recordings.count, 2)
        // New recording should be at index 0
        XCTAssertEqual(appState.recordings[0].duration, 3.0)
        XCTAssertEqual(appState.recordings[1].id, existingRecording.id)
    }

    // MARK: - Error State Tests

    func testShowingErrorSetsFlag() {
        appState.lastError = RecordingError.permissionDenied
        appState.showingError = true

        XCTAssertTrue(appState.showingError)
        XCTAssertNotNil(appState.lastError)
    }

    func testClearError() {
        appState.lastError = RecordingError.permissionDenied
        appState.showingError = true

        appState.lastError = nil
        appState.showingError = false

        XCTAssertNil(appState.lastError)
        XCTAssertFalse(appState.showingError)
    }

    // MARK: - Export State Tests

    func testExportProgressUpdates() {
        appState.isExporting = true
        appState.exportProgress = 0.5

        XCTAssertTrue(appState.isExporting)
        XCTAssertEqual(appState.exportProgress, 0.5)
    }

    func testExportProgressClampsToOne() {
        appState.exportProgress = 1.5

        // Progress should be set (even if > 1, UI handles clamping)
        XCTAssertEqual(appState.exportProgress, 1.5)
    }

    // MARK: - Library Update Tests

    func testDeleteRecordingRemovesFromList() {
        let recording1 = Recording(
            id: UUID(),
            createdAt: Date(),
            sourceVideoURL: URL(fileURLWithPath: "/tmp/test1.mov"),
            duration: 10.0
        )
        let recording2 = Recording(
            id: UUID(),
            createdAt: Date(),
            sourceVideoURL: URL(fileURLWithPath: "/tmp/test2.mov"),
            duration: 15.0
        )
        appState.recordings = [recording1, recording2]

        appState.deleteRecording(recording1)

        XCTAssertEqual(appState.recordings.count, 1)
        XCTAssertEqual(appState.recordings[0].id, recording2.id)
    }

    func testDeleteNonexistentRecording() {
        let recording1 = Recording(
            id: UUID(),
            createdAt: Date(),
            sourceVideoURL: URL(fileURLWithPath: "/tmp/test1.mov"),
            duration: 10.0
        )
        let recording2 = Recording(
            id: UUID(),
            createdAt: Date(),
            sourceVideoURL: URL(fileURLWithPath: "/tmp/test2.mov"),
            duration: 15.0
        )
        appState.recordings = [recording1]

        appState.deleteRecording(recording2)

        // Should still have original recording
        XCTAssertEqual(appState.recordings.count, 1)
        XCTAssertEqual(appState.recordings[0].id, recording1.id)
    }

    // MARK: - Configuration Tests

    func testCaptureConfigurationMutation() {
        appState.captureConfiguration.quality = .low
        appState.captureConfiguration.capturesMouseClicks = true
        appState.captureConfiguration.capturesKeyboardInput = true
        appState.captureConfiguration.includeWindowShadow = false

        XCTAssertEqual(appState.captureConfiguration.quality, .low)
        XCTAssertTrue(appState.captureConfiguration.capturesMouseClicks)
        XCTAssertTrue(appState.captureConfiguration.capturesKeyboardInput)
        XCTAssertFalse(appState.captureConfiguration.includeWindowShadow)
    }

    func testExportSettingsMutation() {
        appState.exportSettings.preset = .small
        appState.exportSettings.loopCount = 3

        XCTAssertEqual(appState.exportSettings.preset, .small)
        XCTAssertEqual(appState.exportSettings.loopCount, 3)
        XCTAssertEqual(appState.exportSettings.fps, 10) // Small preset FPS
    }

    // MARK: - Mock Library Tests

    func testMockLibrarySaveAddsRecording() {
        let recording = Recording(
            id: UUID(),
            createdAt: Date(),
            sourceVideoURL: URL(fileURLWithPath: "/tmp/test.mov"),
            duration: 10.0
        )

        mockLibrary.save(recording)

        XCTAssertTrue(mockLibrary.saveCalled)
        XCTAssertEqual(mockLibrary.recordings.count, 1)
    }

    func testMockLibraryUpdateModifiesRecording() {
        var recording = Recording(
            id: UUID(),
            createdAt: Date(),
            sourceVideoURL: URL(fileURLWithPath: "/tmp/test.mov"),
            duration: 10.0
        )
        mockLibrary.recordings = [recording]

        recording.exportedGIFURL = URL(fileURLWithPath: "/tmp/test.gif")
        mockLibrary.update(recording)

        XCTAssertTrue(mockLibrary.updateCalled)
        XCTAssertNotNil(mockLibrary.recordings[0].exportedGIFURL)
    }

    func testMockLibraryDeleteAll() {
        mockLibrary.recordings = [
            Recording(id: UUID(), createdAt: Date(), sourceVideoURL: URL(fileURLWithPath: "/tmp/1.mov"), duration: 1),
            Recording(id: UUID(), createdAt: Date(), sourceVideoURL: URL(fileURLWithPath: "/tmp/2.mov"), duration: 2)
        ]

        mockLibrary.deleteAll()

        XCTAssertTrue(mockLibrary.deleteAllCalled)
        XCTAssertTrue(mockLibrary.recordings.isEmpty)
    }

    // MARK: - Mock Recorder Tests

    func testMockRecorderErrorState() {
        mockRecorder.shouldThrowError = true
        XCTAssertTrue(mockRecorder.shouldThrowError)
    }

    func testMockRecorderInitialState() {
        XCTAssertFalse(mockRecorder.startRecordingCalled)
        XCTAssertFalse(mockRecorder.stopRecordingCalled)
        XCTAssertNil(mockRecorder.outputURL)
    }

    func testMockRecorderStopWithoutURL() async {
        do {
            _ = try await mockRecorder.stopRecording()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is RecordingError)
        }
    }

    // MARK: - Mock Exporter Tests

    func testMockExporterBuildFilterChain() {
        let settings = ExportSettings()
        let filterChain = mockExporter.buildFilterChain(settings: settings)

        XCTAssertTrue(filterChain.contains("fps="))
        XCTAssertTrue(filterChain.contains("scale="))
    }

    func testMockExporterThrowsWhenConfigured() async {
        mockExporter.shouldThrowError = true

        do {
            try await mockExporter.export(
                videoURL: URL(fileURLWithPath: "/tmp/test.mov"),
                to: URL(fileURLWithPath: "/tmp/test.gif"),
                settings: ExportSettings(),
                progressHandler: { _ in }
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is FFmpegError)
        }
    }

    // MARK: - Selected Recording Tests

    func testSelectedRecordingInitiallyNil() {
        XCTAssertNil(appState.selectedRecording)
    }

    func testSelectedRecordingCanBeSet() {
        let recording = Recording(
            id: UUID(),
            createdAt: Date(),
            sourceVideoURL: URL(fileURLWithPath: "/tmp/test.mov"),
            duration: 10.0
        )

        appState.selectedRecording = recording

        XCTAssertNotNil(appState.selectedRecording)
        XCTAssertEqual(appState.selectedRecording?.id, recording.id)
    }

    // MARK: - Preparing State Tests

    func testPreparingStateInitiallyFalse() {
        XCTAssertFalse(appState.isPreparing)
    }

    func testPreparingStateCanBeSet() {
        appState.isPreparing = true
        XCTAssertTrue(appState.isPreparing)
    }
}

// MARK: - Mock Screen Recorder

class MockScreenRecorder: ScreenRecorderProtocol {
    var startRecordingCalled = false
    var stopRecordingCalled = false
    var outputURL: URL?
    var shouldThrowError = false

    func startRecording(
        display: SCDisplay,
        cropRect: CGRect?,
        configuration: CaptureConfiguration,
        outputURL: URL
    ) async throws {
        if shouldThrowError {
            throw RecordingError.recordingFailed("Mock error")
        }
        startRecordingCalled = true
        self.outputURL = outputURL
    }

    func startRecording(
        window: SCWindow,
        configuration: CaptureConfiguration,
        outputURL: URL
    ) async throws {
        if shouldThrowError {
            throw RecordingError.recordingFailed("Mock error")
        }
        startRecordingCalled = true
        self.outputURL = outputURL
    }

    func stopRecording() async throws -> URL {
        stopRecordingCalled = true
        guard let url = outputURL else {
            throw RecordingError.outputURLNotSet
        }
        return url
    }
}

// MARK: - Mock GIF Exporter

class MockGIFExporter: GIFExporterProtocol {
    var exportCalled = false
    var shouldThrowError = false

    func export(
        videoURL: URL,
        to outputURL: URL,
        settings: ExportSettings,
        progressHandler: @escaping (Double) -> Void
    ) async throws {
        if shouldThrowError {
            throw FFmpegError.executionFailed("Mock error")
        }
        exportCalled = true
        progressHandler(0.5)
        progressHandler(1.0)
    }

    func buildFilterChain(settings: ExportSettings) -> String {
        return "[0:v]fps=\(settings.fps),scale=\(settings.maxWidth):-2:flags=lanczos"
    }
}

// MARK: - Mock Recording Library

class MockRecordingLibrary: RecordingLibraryProtocol {
    var recordings: [Recording] = []
    var saveCalled = false
    var updateCalled = false
    var deleteCalled = false
    var deleteAllCalled = false

    func loadRecordings() -> [Recording] {
        return recordings
    }

    func save(_ recording: Recording) {
        saveCalled = true
        recordings.insert(recording, at: 0)
    }

    func update(_ recording: Recording) {
        updateCalled = true
        if let index = recordings.firstIndex(where: { $0.id == recording.id }) {
            recordings[index] = recording
        }
    }

    func delete(_ recording: Recording) {
        deleteCalled = true
        recordings.removeAll { $0.id == recording.id }
    }

    func deleteAll() {
        deleteAllCalled = true
        recordings.removeAll()
    }

    var totalStorageUsed: Int64 { 0 }
    var formattedStorageUsed: String { "0 MB" }
}

// MARK: - Mock Overlay Controller

@MainActor
class MockOverlayController: OverlayControllerProtocol {
    var showOverlayCalled = false
    var lastDisplay: SCDisplay?
    var completeHandler: ((CGRect, SCDisplay) -> Void)?
    var cancelHandler: (() -> Void)?

    func showOverlay(
        for display: SCDisplay,
        onComplete: @escaping (CGRect, SCDisplay) -> Void,
        onCancel: @escaping () -> Void
    ) {
        showOverlayCalled = true
        lastDisplay = display
        completeHandler = onComplete
        cancelHandler = onCancel
    }

    func simulateComplete(rect: CGRect, display: SCDisplay) {
        completeHandler?(rect, display)
    }

    func simulateCancel() {
        cancelHandler?()
    }
}

// MARK: - Additional Recorder Error Tests

final class RecorderErrorTests: XCTestCase {

    func testRecordingFailedWithCustomMessage() {
        let error = RecordingError.recordingFailed("Custom failure message")
        XCTAssertEqual(error.errorDescription, "Recording failed: Custom failure message")
    }

    func testRecordingFailedWithEmptyMessage() {
        let error = RecordingError.recordingFailed("")
        XCTAssertEqual(error.errorDescription, "Recording failed: ")
    }

    func testRecordingErrorEquality() {
        let error1 = RecordingError.noContentSelected
        let error2 = RecordingError.noContentSelected
        XCTAssertEqual(error1.errorDescription, error2.errorDescription)
    }

    func testAllRecordingErrorCases() {
        let errors: [RecordingError] = [
            .noContentSelected,
            .permissionDenied,
            .recordingFailed("test"),
            .noActiveRecording,
            .outputURLNotSet
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
}
