import Foundation
import Testing

@testable import AnimaMac

@Suite("RecordingLibrary")
struct RecordingLibraryTests {

    private func withTempDir(_ body: (URL, RecordingLibrary) throws -> Void) throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("AnimaMacTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let libraryURL = tempDir.appendingPathComponent("library.json")
        let library = RecordingLibrary(libraryURL: libraryURL)
        try body(tempDir, library)
    }

    private func makeRecording(in dir: URL, name: String = UUID().uuidString) -> Recording {
        Recording(
            id: UUID(),
            createdAt: Date(),
            sourceVideoURL: dir.appendingPathComponent("\(name).mov"),
            duration: 5.0
        )
    }

    // MARK: - Load

    @Test("Returns empty when no file exists")
    func loadEmpty() throws {
        try withTempDir { _, library in
            #expect(library.loadRecordings().isEmpty)
        }
    }

    @Test("Returns empty for corrupted JSON")
    func loadCorrupted() throws {
        try withTempDir { dir, library in
            let libraryURL = dir.appendingPathComponent("library.json")
            try "not json".data(using: .utf8)!.write(to: libraryURL)
            #expect(library.loadRecordings().isEmpty)
        }
    }

    @Test("Filters out recordings with missing files")
    func loadFiltersMissing() throws {
        try withTempDir { dir, library in
            let recording = makeRecording(in: dir)
            // Don't create the video file
            let libraryURL = dir.appendingPathComponent("library.json")
            try JSONEncoder().encode([recording]).write(to: libraryURL)
            #expect(library.loadRecordings().isEmpty)
        }
    }

    @Test("Returns recordings with existing files")
    func loadWithExistingFiles() throws {
        try withTempDir { dir, library in
            let recording = makeRecording(in: dir)
            try Data().write(to: recording.sourceVideoURL)
            let libraryURL = dir.appendingPathComponent("library.json")
            try JSONEncoder().encode([recording]).write(to: libraryURL)
            let loaded = library.loadRecordings()
            #expect(loaded.count == 1)
            #expect(loaded.first?.id == recording.id)
        }
    }

    // MARK: - Save

    @Test("Save creates the library file")
    func saveCreatesFile() throws {
        try withTempDir { dir, library in
            let recording = makeRecording(in: dir)
            try Data().write(to: recording.sourceVideoURL)
            library.save(recording)
            let libraryURL = dir.appendingPathComponent("library.json")
            #expect(FileManager.default.fileExists(atPath: libraryURL.path))
        }
    }

    @Test("Save inserts at beginning")
    func saveInsertsAtBeginning() throws {
        try withTempDir { dir, library in
            let r1 = makeRecording(in: dir, name: "v1")
            let r2 = makeRecording(in: dir, name: "v2")
            try Data().write(to: r1.sourceVideoURL)
            try Data().write(to: r2.sourceVideoURL)
            library.save(r1)
            library.save(r2)
            let loaded = library.loadRecordings()
            #expect(loaded.count == 2)
            #expect(loaded.first?.id == r2.id)
        }
    }

    // MARK: - Update

    @Test("Update modifies existing recording")
    func updateModifies() throws {
        try withTempDir { dir, library in
            let gifURL = dir.appendingPathComponent("video.gif")
            var recording = makeRecording(in: dir)
            try Data().write(to: recording.sourceVideoURL)
            library.save(recording)
            recording.exportedGIFURL = gifURL
            library.update(recording)
            let loaded = library.loadRecordings()
            #expect(loaded.first?.exportedGIFURL == gifURL)
        }
    }

    @Test("Update ignores unknown ID")
    func updateIgnoresUnknown() throws {
        try withTempDir { dir, library in
            let existing = makeRecording(in: dir, name: "existing")
            try Data().write(to: existing.sourceVideoURL)
            library.save(existing)
            let unknown = makeRecording(in: dir, name: "unknown")
            try Data().write(to: unknown.sourceVideoURL)
            library.update(unknown)
            let loaded = library.loadRecordings()
            #expect(loaded.count == 1)
            #expect(loaded.first?.id == existing.id)
        }
    }

    // MARK: - Delete

    @Test("Delete removes recording from library")
    func deleteRemovesFromLibrary() throws {
        try withTempDir { dir, library in
            let recording = makeRecording(in: dir)
            try Data().write(to: recording.sourceVideoURL)
            library.save(recording)
            library.delete(recording)
            #expect(library.loadRecordings().isEmpty)
        }
    }

    @Test("Delete removes video file")
    func deleteRemovesVideoFile() throws {
        try withTempDir { dir, library in
            let recording = makeRecording(in: dir)
            try Data().write(to: recording.sourceVideoURL)
            library.save(recording)
            library.delete(recording)
            #expect(!FileManager.default.fileExists(atPath: recording.sourceVideoURL.path))
        }
    }

    @Test("Delete removes GIF file")
    func deleteRemovesGIFFile() throws {
        try withTempDir { dir, library in
            let gifURL = dir.appendingPathComponent("video.gif")
            var recording = makeRecording(in: dir)
            recording.exportedGIFURL = gifURL
            try Data().write(to: recording.sourceVideoURL)
            try Data().write(to: gifURL)
            library.save(recording)
            library.delete(recording)
            #expect(!FileManager.default.fileExists(atPath: gifURL.path))
        }
    }

    // MARK: - DeleteAll

    @Test("DeleteAll removes everything")
    func deleteAll() throws {
        try withTempDir { dir, library in
            let r1 = makeRecording(in: dir, name: "v1")
            let r2 = makeRecording(in: dir, name: "v2")
            try Data().write(to: r1.sourceVideoURL)
            try Data().write(to: r2.sourceVideoURL)
            library.save(r1)
            library.save(r2)
            library.deleteAll()
            #expect(library.loadRecordings().isEmpty)
            #expect(!FileManager.default.fileExists(atPath: r1.sourceVideoURL.path))
            #expect(!FileManager.default.fileExists(atPath: r2.sourceVideoURL.path))
        }
    }

    // MARK: - Storage Info

    @Test("Total storage used sums file sizes")
    func totalStorageUsed() throws {
        try withTempDir { dir, library in
            let recording = makeRecording(in: dir)
            try Data(repeating: 0, count: 2048).write(to: recording.sourceVideoURL)
            library.save(recording)
            #expect(library.totalStorageUsed == 2048)
        }
    }

    @Test("Formatted storage used is non-empty")
    func formattedStorageUsed() throws {
        try withTempDir { _, library in
            #expect(!library.formattedStorageUsed.isEmpty)
        }
    }
}
