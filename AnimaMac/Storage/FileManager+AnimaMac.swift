import Foundation

extension FileManager {
    /// ~/Library/Application Support/AnimaMac/
    static var animaMacDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let animaMacDir = appSupport.appendingPathComponent("AnimaMac", isDirectory: true)

        // Create directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: animaMacDir.path) {
            try? FileManager.default.createDirectory(at: animaMacDir, withIntermediateDirectories: true)
        }

        return animaMacDir
    }

    /// ~/Library/Application Support/AnimaMac/recordings/
    static var animaMacRecordingsDirectory: URL {
        let recordingsDir = animaMacDirectory.appendingPathComponent("recordings", isDirectory: true)

        if !FileManager.default.fileExists(atPath: recordingsDir.path) {
            try? FileManager.default.createDirectory(at: recordingsDir, withIntermediateDirectories: true)
        }

        return recordingsDir
    }

    /// ~/Library/Application Support/AnimaMac/ffmpeg
    static var ffmpegBinaryURL: URL {
        animaMacDirectory.appendingPathComponent("ffmpeg")
    }

    /// Check if FFmpeg is available
    static var isFFmpegAvailable: Bool {
        FileManager.default.fileExists(atPath: ffmpegBinaryURL.path)
    }
}
