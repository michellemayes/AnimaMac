import Foundation
import Testing

@testable import AnimaMac

@Suite("FileManager Extension")
struct FileManagerExtensionTests {

    @Test("animaMacDirectory is in Application Support")
    func animaMacDirectoryPath() {
        let dir = FileManager.animaMacDirectory
        #expect(dir.path.contains("Application Support"))
        #expect(dir.path.contains("AnimaMac"))
    }

    @Test("animaMacDirectory exists")
    func animaMacDirectoryExists() {
        let dir = FileManager.animaMacDirectory
        var isDir: ObjCBool = false
        #expect(FileManager.default.fileExists(atPath: dir.path, isDirectory: &isDir))
        #expect(isDir.boolValue)
    }

    @Test("recordingsDirectory is subdirectory of animaMacDirectory")
    func recordingsDirectoryPath() {
        let recordings = FileManager.animaMacRecordingsDirectory
        let parent = FileManager.animaMacDirectory
        #expect(recordings.path.hasPrefix(parent.path))
        #expect(recordings.path.contains("recordings"))
    }

    @Test("recordingsDirectory exists")
    func recordingsDirectoryExists() {
        let dir = FileManager.animaMacRecordingsDirectory
        var isDir: ObjCBool = false
        #expect(FileManager.default.fileExists(atPath: dir.path, isDirectory: &isDir))
        #expect(isDir.boolValue)
    }

    @Test("ffmpegBinaryURL is in animaMacDirectory")
    func ffmpegURLPath() {
        let url = FileManager.ffmpegBinaryURL
        let parent = FileManager.animaMacDirectory
        #expect(url.path.hasPrefix(parent.path))
        #expect(url.lastPathComponent == "ffmpeg")
    }

    @Test("isFFmpegAvailable returns without crashing")
    func isFFmpegAvailable() {
        _ = FileManager.isFFmpegAvailable
    }

    @Test("Directory paths are stable across calls")
    func stablePaths() {
        #expect(FileManager.animaMacDirectory == FileManager.animaMacDirectory)
        #expect(FileManager.animaMacRecordingsDirectory == FileManager.animaMacRecordingsDirectory)
        #expect(FileManager.ffmpegBinaryURL == FileManager.ffmpegBinaryURL)
    }
}
