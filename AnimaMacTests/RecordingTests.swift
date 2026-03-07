import XCTest
@testable import AnimaMacCore

final class RecordingTests: XCTestCase {

    // MARK: - Initialization

    func testInitialization() {
        let id = UUID()
        let date = Date()
        let videoURL = URL(fileURLWithPath: "/tmp/test.mov")

        let recording = Recording(
            id: id,
            createdAt: date,
            sourceVideoURL: videoURL,
            duration: 10.5
        )

        XCTAssertEqual(recording.id, id)
        XCTAssertEqual(recording.createdAt, date)
        XCTAssertEqual(recording.sourceVideoURL, videoURL)
        XCTAssertNil(recording.exportedGIFURL)
        XCTAssertEqual(recording.duration, 10.5)
    }

    func testInitializationWithGIF() {
        let id = UUID()
        let date = Date()
        let videoURL = URL(fileURLWithPath: "/tmp/test.mov")
        let gifURL = URL(fileURLWithPath: "/tmp/test.gif")

        let recording = Recording(
            id: id,
            createdAt: date,
            sourceVideoURL: videoURL,
            exportedGIFURL: gifURL,
            duration: 5.0
        )

        XCTAssertEqual(recording.exportedGIFURL, gifURL)
    }

    // MARK: - Formatted Duration

    func testFormattedDurationSeconds() {
        let recording = createRecording(duration: 45)
        XCTAssertEqual(recording.formattedDuration, "45s")
    }

    func testFormattedDurationMinutesAndSeconds() {
        let recording = createRecording(duration: 125)  // 2m 5s
        XCTAssertEqual(recording.formattedDuration, "2m 5s")
    }

    func testFormattedDurationExactMinute() {
        let recording = createRecording(duration: 60)
        XCTAssertEqual(recording.formattedDuration, "1m 0s")
    }

    func testFormattedDurationZero() {
        let recording = createRecording(duration: 0)
        XCTAssertEqual(recording.formattedDuration, "0s")
    }

    func testFormattedDurationFractionalSeconds() {
        let recording = createRecording(duration: 10.7)
        XCTAssertEqual(recording.formattedDuration, "10s")  // Truncates to Int
    }

    // MARK: - Display Name

    func testDisplayNameFormat() {
        let date = Date()
        let recording = Recording(
            id: UUID(),
            createdAt: date,
            sourceVideoURL: URL(fileURLWithPath: "/tmp/test.mov"),
            duration: 10
        )

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        let expected = formatter.string(from: date)

        XCTAssertEqual(recording.displayName, expected)
    }

    // MARK: - File Size

    func testFileSizeForNonexistentFile() {
        let recording = createRecording(duration: 10)
        XCTAssertNil(recording.fileSize)
    }

    func testFormattedFileSizeForNonexistentFile() {
        let recording = createRecording(duration: 10)
        XCTAssertEqual(recording.formattedFileSize, "Unknown")
    }

    func testFileSizeForExistingFile() throws {
        // Create a temporary file with known content
        let tempDir = FileManager.default.temporaryDirectory
        let testFile = tempDir.appendingPathComponent("test_\(UUID().uuidString).mov")

        let testData = Data(repeating: 0x42, count: 1024)  // 1 KB
        try testData.write(to: testFile)

        defer {
            try? FileManager.default.removeItem(at: testFile)
        }

        let recording = Recording(
            id: UUID(),
            createdAt: Date(),
            sourceVideoURL: testFile,
            duration: 10
        )

        XCTAssertEqual(recording.fileSize, 1024)
    }

    // MARK: - Codable

    func testEncodeDecode() throws {
        let original = Recording(
            id: UUID(),
            createdAt: Date(),
            sourceVideoURL: URL(fileURLWithPath: "/tmp/test.mov"),
            exportedGIFURL: URL(fileURLWithPath: "/tmp/test.gif"),
            duration: 15.5
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Recording.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.sourceVideoURL, original.sourceVideoURL)
        XCTAssertEqual(decoded.exportedGIFURL, original.exportedGIFURL)
        XCTAssertEqual(decoded.duration, original.duration)
    }

    // MARK: - Equatable

    func testEquality() {
        let id = UUID()
        let date = Date()
        let url = URL(fileURLWithPath: "/tmp/test.mov")

        let recording1 = Recording(id: id, createdAt: date, sourceVideoURL: url, duration: 10)
        let recording2 = Recording(id: id, createdAt: date, sourceVideoURL: url, duration: 10)

        XCTAssertEqual(recording1, recording2)
    }

    func testInequalityDifferentID() {
        let url = URL(fileURLWithPath: "/tmp/test.mov")
        let date = Date()

        let recording1 = Recording(id: UUID(), createdAt: date, sourceVideoURL: url, duration: 10)
        let recording2 = Recording(id: UUID(), createdAt: date, sourceVideoURL: url, duration: 10)

        XCTAssertNotEqual(recording1, recording2)
    }

    // MARK: - Identifiable

    func testIdentifiable() {
        let id = UUID()
        let recording = Recording(
            id: id,
            createdAt: Date(),
            sourceVideoURL: URL(fileURLWithPath: "/tmp/test.mov"),
            duration: 10
        )

        XCTAssertEqual(recording.id, id)
    }

    // MARK: - Helpers

    private func createRecording(duration: TimeInterval) -> Recording {
        Recording(
            id: UUID(),
            createdAt: Date(),
            sourceVideoURL: URL(fileURLWithPath: "/tmp/test.mov"),
            duration: duration
        )
    }
}
