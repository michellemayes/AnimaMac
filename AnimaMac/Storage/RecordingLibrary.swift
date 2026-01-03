import Foundation

final class RecordingLibrary {
    private let libraryURL: URL

    init() {
        libraryURL = FileManager.animaMacDirectory.appendingPathComponent("library.json")
    }

    // MARK: - CRUD Operations

    func loadRecordings() -> [Recording] {
        guard FileManager.default.fileExists(atPath: libraryURL.path) else {
            return []
        }

        do {
            let data = try Data(contentsOf: libraryURL)
            let recordings = try JSONDecoder().decode([Recording].self, from: data)

            // Filter out recordings whose files no longer exist
            return recordings.filter { recording in
                FileManager.default.fileExists(atPath: recording.sourceVideoURL.path)
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
        try? FileManager.default.removeItem(at: recording.sourceVideoURL)
        if let gifURL = recording.exportedGIFURL {
            try? FileManager.default.removeItem(at: gifURL)
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
            try data.write(to: libraryURL, options: .atomic)
        } catch {
            print("Failed to save recordings: \(error)")
        }
    }

    // MARK: - Storage Info

    var totalStorageUsed: Int64 {
        let recordings = loadRecordings()
        return recordings.compactMap { $0.fileSize }.reduce(0, +)
    }

    var formattedStorageUsed: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalStorageUsed)
    }
}
