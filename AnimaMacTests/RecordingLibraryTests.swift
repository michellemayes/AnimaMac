import XCTest
@testable import AnimaMacCore

final class RecordingLibraryTests: XCTestCase {

    var tempDir: URL!
    var library: RecordingLibrary!

    override func setUp() {
        super.setUp()
        // Create a unique temp directory for each test
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("AnimaMacTests_\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        // Use the real RecordingLibrary with a custom base directory
        library = RecordingLibrary(baseDirectory: tempDir)
    }

    override func tearDown() {
        // Clean up temp directory
        try? FileManager.default.removeItem(at: tempDir)
        library = nil
        tempDir = nil
        super.tearDown()
    }

    // MARK: - Load Empty Library

    func testLoadEmptyLibrary() {
        let recordings = library.loadRecordings()
        XCTAssertTrue(recordings.isEmpty)
    }

    // MARK: - Save and Load

    func testSaveAndLoadRecording() throws {
        // Create a temp video file
        let videoURL = tempDir.appendingPathComponent("test.mov")
        try Data("test".utf8).write(to: videoURL)

        let recording = Recording(
            id: UUID(),
            createdAt: Date(),
            sourceVideoURL: videoURL,
            duration: 10.0
        )

        library.save(recording)

        let loaded = library.loadRecordings()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.id, recording.id)
        XCTAssertEqual(loaded.first?.duration, 10.0)
    }

    func testSaveMultipleRecordings() throws {
        let videoURL1 = tempDir.appendingPathComponent("test1.mov")
        let videoURL2 = tempDir.appendingPathComponent("test2.mov")
        try Data("test".utf8).write(to: videoURL1)
        try Data("test".utf8).write(to: videoURL2)

        let recording1 = Recording(id: UUID(), createdAt: Date(), sourceVideoURL: videoURL1, duration: 5.0)
        let recording2 = Recording(id: UUID(), createdAt: Date(), sourceVideoURL: videoURL2, duration: 10.0)

        library.save(recording1)
        library.save(recording2)

        let loaded = library.loadRecordings()
        XCTAssertEqual(loaded.count, 2)

        // Most recent should be first
        XCTAssertEqual(loaded.first?.id, recording2.id)
    }

    // MARK: - Update

    func testUpdateRecording() throws {
        let videoURL = tempDir.appendingPathComponent("test.mov")
        let gifURL = tempDir.appendingPathComponent("test.gif")
        try Data("test".utf8).write(to: videoURL)
        try Data("test".utf8).write(to: gifURL)

        var recording = Recording(
            id: UUID(),
            createdAt: Date(),
            sourceVideoURL: videoURL,
            duration: 10.0
        )

        library.save(recording)

        // Update with GIF URL
        recording.exportedGIFURL = gifURL
        library.update(recording)

        let loaded = library.loadRecordings()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.exportedGIFURL, gifURL)
    }

    func testUpdateNonexistentRecording() throws {
        let videoURL = tempDir.appendingPathComponent("test.mov")
        try Data("test".utf8).write(to: videoURL)

        let recording = Recording(
            id: UUID(),
            createdAt: Date(),
            sourceVideoURL: videoURL,
            duration: 10.0
        )

        // Try to update without saving first
        library.update(recording)

        let loaded = library.loadRecordings()
        XCTAssertTrue(loaded.isEmpty)
    }

    // MARK: - Delete

    func testDeleteRecording() throws {
        let videoURL = tempDir.appendingPathComponent("test.mov")
        try Data("test".utf8).write(to: videoURL)

        let recording = Recording(
            id: UUID(),
            createdAt: Date(),
            sourceVideoURL: videoURL,
            duration: 10.0
        )

        library.save(recording)
        XCTAssertEqual(library.loadRecordings().count, 1)

        library.delete(recording)

        let loaded = library.loadRecordings()
        XCTAssertTrue(loaded.isEmpty)

        // Video file should also be deleted
        XCTAssertFalse(FileManager.default.fileExists(atPath: videoURL.path))
    }

    func testDeleteRecordingWithGIF() throws {
        let videoURL = tempDir.appendingPathComponent("test.mov")
        let gifURL = tempDir.appendingPathComponent("test.gif")
        try Data("test".utf8).write(to: videoURL)
        try Data("test".utf8).write(to: gifURL)

        var recording = Recording(
            id: UUID(),
            createdAt: Date(),
            sourceVideoURL: videoURL,
            duration: 10.0
        )
        recording.exportedGIFURL = gifURL

        library.save(recording)
        library.delete(recording)

        // Both files should be deleted
        XCTAssertFalse(FileManager.default.fileExists(atPath: videoURL.path))
        XCTAssertFalse(FileManager.default.fileExists(atPath: gifURL.path))
    }

    func testDeleteAll() throws {
        let videoURL1 = tempDir.appendingPathComponent("test1.mov")
        let videoURL2 = tempDir.appendingPathComponent("test2.mov")
        try Data("test".utf8).write(to: videoURL1)
        try Data("test".utf8).write(to: videoURL2)

        library.save(Recording(id: UUID(), createdAt: Date(), sourceVideoURL: videoURL1, duration: 5.0))
        library.save(Recording(id: UUID(), createdAt: Date(), sourceVideoURL: videoURL2, duration: 10.0))

        XCTAssertEqual(library.loadRecordings().count, 2)

        library.deleteAll()

        XCTAssertTrue(library.loadRecordings().isEmpty)
    }

    // MARK: - Filter Missing Files

    func testFilterOutMissingFiles() throws {
        let videoURL1 = tempDir.appendingPathComponent("test1.mov")
        let videoURL2 = tempDir.appendingPathComponent("test2.mov")
        try Data("test".utf8).write(to: videoURL1)
        try Data("test".utf8).write(to: videoURL2)

        library.save(Recording(id: UUID(), createdAt: Date(), sourceVideoURL: videoURL1, duration: 5.0))
        library.save(Recording(id: UUID(), createdAt: Date(), sourceVideoURL: videoURL2, duration: 10.0))

        // Delete one video file directly (simulating external deletion)
        try FileManager.default.removeItem(at: videoURL1)

        let loaded = library.loadRecordings()
        XCTAssertEqual(loaded.count, 1)
        XCTAssertEqual(loaded.first?.sourceVideoURL, videoURL2)
    }

    // MARK: - Storage Info

    func testTotalStorageUsed() throws {
        let videoURL = tempDir.appendingPathComponent("test.mov")
        let testData = Data(repeating: 0x42, count: 2048)  // 2 KB
        try testData.write(to: videoURL)

        let recording = Recording(
            id: UUID(),
            createdAt: Date(),
            sourceVideoURL: videoURL,
            duration: 10.0
        )

        library.save(recording)

        XCTAssertEqual(library.totalStorageUsed, 2048)
    }

    func testFormattedStorageUsed() throws {
        let videoURL = tempDir.appendingPathComponent("test.mov")
        let testData = Data(repeating: 0x42, count: 1024 * 1024)  // 1 MB
        try testData.write(to: videoURL)

        let recording = Recording(
            id: UUID(),
            createdAt: Date(),
            sourceVideoURL: videoURL,
            duration: 10.0
        )

        library.save(recording)

        let formatted = library.formattedStorageUsed
        XCTAssertTrue(formatted.contains("MB") || formatted.contains("KB"))
    }

    // MARK: - FileSystemProtocol Tests

    func testFileSystemProtocolInjection() throws {
        let mockFileSystem = MockFileSystem()
        let library = RecordingLibrary(baseDirectory: tempDir, fileSystem: mockFileSystem)

        // Should use the mock file system
        _ = library.loadRecordings()
        XCTAssertTrue(mockFileSystem.fileExistsCalled)
    }

    // MARK: - Edge Cases

    func testLoadCorruptedLibraryFile() throws {
        // Write invalid JSON to library file
        let libraryURL = tempDir.appendingPathComponent("library.json")
        try Data("not valid json".utf8).write(to: libraryURL)

        let loaded = library.loadRecordings()
        XCTAssertTrue(loaded.isEmpty)
    }

    func testSaveAndLoadPreservesAllFields() throws {
        let videoURL = tempDir.appendingPathComponent("test.mov")
        let gifURL = tempDir.appendingPathComponent("test.gif")
        try Data("test".utf8).write(to: videoURL)
        try Data("test".utf8).write(to: gifURL)

        let id = UUID()
        let date = Date()
        var recording = Recording(
            id: id,
            createdAt: date,
            sourceVideoURL: videoURL,
            duration: 42.5
        )
        recording.exportedGIFURL = gifURL

        library.save(recording)

        let loaded = library.loadRecordings().first!
        XCTAssertEqual(loaded.id, id)
        XCTAssertEqual(loaded.sourceVideoURL, videoURL)
        XCTAssertEqual(loaded.exportedGIFURL, gifURL)
        XCTAssertEqual(loaded.duration, 42.5)
    }
}

// MARK: - Mock File System

class MockFileSystem: FileSystemProtocol {
    var fileExistsCalled = false
    var existingFiles: Set<String> = []
    var fileContents: [String: Data] = [:]
    var removedFiles: [URL] = []

    func fileExists(atPath path: String) -> Bool {
        fileExistsCalled = true
        return existingFiles.contains(path)
    }

    func removeItem(at url: URL) throws {
        removedFiles.append(url)
    }

    func createDirectory(at url: URL, withIntermediateDirectories: Bool, attributes: [FileAttributeKey: Any]?) throws {
        // No-op for testing
    }

    func contentsOfFile(at url: URL) throws -> Data {
        guard let data = fileContents[url.path] else {
            throw NSError(domain: "MockFileSystem", code: 1, userInfo: nil)
        }
        return data
    }

    func write(_ data: Data, to url: URL, options: Data.WritingOptions) throws {
        fileContents[url.path] = data
    }

    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any] {
        return [.size: Int64(1024)]
    }
}
