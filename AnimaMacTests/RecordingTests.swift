import Foundation
import Testing

@testable import AnimaMac

@Suite("Recording Model")
struct RecordingTests {

    // MARK: - formattedDuration

    @Test("Formats seconds only")
    func formattedDurationSecondsOnly() {
        let recording = makeRecording(duration: 45)
        #expect(recording.formattedDuration == "45s")
    }

    @Test("Formats minutes and seconds")
    func formattedDurationWithMinutes() {
        let recording = makeRecording(duration: 125)
        #expect(recording.formattedDuration == "2m 5s")
    }

    @Test("Formats zero duration")
    func formattedDurationZero() {
        let recording = makeRecording(duration: 0)
        #expect(recording.formattedDuration == "0s")
    }

    @Test("Formats exact minute")
    func formattedDurationExactMinute() {
        let recording = makeRecording(duration: 60)
        #expect(recording.formattedDuration == "1m 0s")
    }

    @Test("Truncates fractional seconds")
    func formattedDurationFractional() {
        let recording = makeRecording(duration: 5.9)
        #expect(recording.formattedDuration == "5s")
    }

    // MARK: - displayName

    @Test("Display name is not empty")
    func displayNameNotEmpty() {
        let recording = makeRecording()
        #expect(!recording.displayName.isEmpty)
    }

    // MARK: - fileSize

    @Test("Returns nil for nonexistent file")
    func fileSizeNilForMissingFile() {
        let recording = makeRecording()
        #expect(recording.fileSize == nil)
    }

    @Test("Returns 'Unknown' for nonexistent file")
    func formattedFileSizeUnknown() {
        let recording = makeRecording()
        #expect(recording.formattedFileSize == "Unknown")
    }

    @Test("Returns correct size for existing file")
    func fileSizeForExistingFile() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".mov")
        try Data(repeating: 0, count: 1024).write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let recording = makeRecording(sourceVideoURL: tempURL)
        #expect(recording.fileSize == 1024)
    }

    @Test("Formatted size is not 'Unknown' for existing file")
    func formattedFileSizeForExistingFile() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".mov")
        try Data(repeating: 0, count: 2048).write(to: tempURL)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let recording = makeRecording(sourceVideoURL: tempURL)
        #expect(recording.formattedFileSize != "Unknown")
    }

    @Test("Uses GIF URL for file size when available")
    func fileSizeUsesGIFURL() throws {
        let videoURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + "-v.mov")
        let gifURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + "-g.gif")
        try Data(repeating: 0, count: 100).write(to: videoURL)
        try Data(repeating: 0, count: 500).write(to: gifURL)
        defer {
            try? FileManager.default.removeItem(at: videoURL)
            try? FileManager.default.removeItem(at: gifURL)
        }

        var recording = makeRecording(sourceVideoURL: videoURL)
        recording.exportedGIFURL = gifURL
        #expect(recording.fileSize == 500)
    }

    // MARK: - Codable

    @Test("Round-trips through JSON")
    func codableRoundTrip() throws {
        let original = makeRecording(duration: 42.5)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Recording.self, from: data)
        #expect(original == decoded)
    }

    @Test("Round-trips with GIF URL")
    func codableWithGIF() throws {
        var original = makeRecording()
        original.exportedGIFURL = URL(fileURLWithPath: "/tmp/test.gif")
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Recording.self, from: data)
        #expect(decoded.exportedGIFURL == original.exportedGIFURL)
    }

    // MARK: - Helpers

    private func makeRecording(
        createdAt: Date = Date(),
        sourceVideoURL: URL = URL(fileURLWithPath: "/tmp/nonexistent.mov"),
        duration: TimeInterval = 10
    ) -> Recording {
        Recording(id: UUID(), createdAt: createdAt, sourceVideoURL: sourceVideoURL, duration: duration)
    }
}
