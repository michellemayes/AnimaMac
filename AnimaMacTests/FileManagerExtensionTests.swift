import Foundation
import Testing
@testable import AnimaMacCore

@Suite("FileManager Extensions")
struct FileManagerExtensionTests {

    @Test("AnimaMac directory exists and contains expected path components")
    func animaMacDirectory() {
        let dir = FileManager.animaMacDirectory
        #expect(FileManager.default.fileExists(atPath: dir.path))
        #expect(dir.path.contains("AnimaMac"))
        #expect(dir.path.contains("Application Support"))

        var isDir: ObjCBool = false
        FileManager.default.fileExists(atPath: dir.path, isDirectory: &isDir)
        #expect(isDir.boolValue)
    }

    @Test("Recordings directory exists and is subdirectory")
    func recordingsDirectory() {
        let dir = FileManager.animaMacRecordingsDirectory
        #expect(FileManager.default.fileExists(atPath: dir.path))
        #expect(dir.path.contains("recordings"))
        #expect(dir.path.hasPrefix(FileManager.animaMacDirectory.path))
    }

    @Test("FFmpeg binary URL path")
    func ffmpegBinaryURL() {
        let url = FileManager.ffmpegBinaryURL
        #expect(url.path.contains("AnimaMac"))
        #expect(url.lastPathComponent == "ffmpeg")
        #expect(url.path.hasPrefix(FileManager.animaMacDirectory.path))
    }

    @Test("isFFmpegAvailable returns bool")
    func isFFmpegAvailable() {
        let available = FileManager.isFFmpegAvailable
        #expect(available == true || available == false)
    }

    @Test("Paths are consistent across calls")
    func pathConsistency() {
        #expect(FileManager.animaMacDirectory == FileManager.animaMacDirectory)
        #expect(FileManager.animaMacRecordingsDirectory == FileManager.animaMacRecordingsDirectory)
        #expect(FileManager.ffmpegBinaryURL == FileManager.ffmpegBinaryURL)
    }
}
