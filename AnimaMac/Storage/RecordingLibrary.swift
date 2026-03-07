import Foundation

// MARK: - File System Protocol

protocol FileSystemProtocol {
    func fileExists(atPath path: String) -> Bool
    func removeItem(at URL: URL) throws
    func createDirectory(at url: URL, withIntermediateDirectories: Bool, attributes: [FileAttributeKey: Any]?) throws
    func contentsOfFile(at url: URL) throws -> Data
    func write(_ data: Data, to url: URL, options: Data.WritingOptions) throws
    func attributesOfItem(atPath path: String) throws -> [FileAttributeKey: Any]
}

// MARK: - Default Implementation

extension FileManager: FileSystemProtocol {
    func contentsOfFile(at url: URL) throws -> Data {
        try Data(contentsOf: url)
    }

    func write(_ data: Data, to url: URL, options: Data.WritingOptions) throws {
        try data.write(to: url, options: options)
    }
}

// MARK: - Recording Library Protocol

protocol RecordingLibraryProtocol {
    func loadRecordings() -> [Recording]
    func save(_ recording: Recording)
    func update(_ recording: Recording)
    func delete(_ recording: Recording)
    func deleteAll()
    var totalStorageUsed: Int64 { get }
    var formattedStorageUsed: String { get }
}

// MARK: - Recording Library

final class RecordingLibrary: RecordingLibraryProtocol {
    private let libraryURL: URL
    private let baseDirectory: URL
    let fileSystem: FileSystemProtocol

    init(baseDirectory: URL? = nil, fileSystem: FileSystemProtocol = FileManager.default) {
        self.fileSystem = fileSystem
        self.baseDirectory = baseDirectory ?? FileManager.animaMacDirectory
        self.libraryURL = self.baseDirectory.appendingPathComponent("library.json")
    }

    // MARK: - CRUD Operations

    func loadRecordings() -> [Recording] {
        guard fileSystem.fileExists(atPath: libraryURL.path) else {
            return []
        }

        do {
            let data = try fileSystem.contentsOfFile(at: libraryURL)
            let recordings = try JSONDecoder().decode([Recording].self, from: data)

            // Filter out recordings whose files no longer exist
            return recordings.filter { recording in
                fileSystem.fileExists(atPath: recording.sourceVideoURL.path)
            }
        } catch {
            print("Failed to load recordings: \(error)")
            return []
        }
    }

    func save(_ recording: Recording) {
        var recordings = loadRecordings()
        recordings.insert(recording, at: 0)
        persist(recordings)
    }

    func update(_ recording: Recording) {
        var recordings = loadRecordings()
        if let index = recordings.firstIndex(where: { $0.id == recording.id }) {
            recordings[index] = recording
            persist(recordings)
        }
    }

    func delete(_ recording: Recording) {
        var recordings = loadRecordings()
        recordings.removeAll { $0.id == recording.id }
        persist(recordings)

        // Delete files
        try? fileSystem.removeItem(at: recording.sourceVideoURL)
        if let gifURL = recording.exportedGIFURL {
            try? fileSystem.removeItem(at: gifURL)
        }
    }

    func deleteAll() {
        let recordings = loadRecordings()
        for recording in recordings {
            delete(recording)
        }
    }

    // MARK: - Persistence

    private func persist(_ recordings: [Recording]) {
        do {
            let data = try JSONEncoder().encode(recordings)
            try fileSystem.write(data, to: libraryURL, options: .atomic)
        } catch {
            print("Failed to save recordings: \(error)")
        }
    }

    // MARK: - Storage Info

    func totalStorageUsed(using fileSystem: FileSystemProtocol? = nil) -> Int64 {
        let fs = fileSystem ?? self.fileSystem
        let recordings = loadRecordings()
        return recordings.compactMap { recording -> Int64? in
            guard let attrs = try? fs.attributesOfItem(atPath: recording.sourceVideoURL.path),
                  let size = attrs[.size] as? Int64 else {
                return nil
            }
            return size
        }.reduce(0, +)
    }

    var totalStorageUsed: Int64 {
        totalStorageUsed(using: nil)
    }

    var formattedStorageUsed: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalStorageUsed)
    }
}
