import Foundation

struct Recording: Identifiable, Codable, Equatable {
    let id: UUID
    let createdAt: Date
    let sourceVideoURL: URL
    var exportedGIFURL: URL?
    var duration: TimeInterval

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }

    var displayName: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }

    var fileSize: Int64? {
        let url = exportedGIFURL ?? sourceVideoURL
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path) else {
            return nil
        }
        return attrs[.size] as? Int64
    }

    var formattedFileSize: String {
        guard let size = fileSize else { return "Unknown" }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}
