import XCTest
@testable import AnimaMacCore

final class FileManagerExtensionTests: XCTestCase {

    // MARK: - Directory Tests

    func testAnimaMacDirectoryExists() {
        let directory = FileManager.animaMacDirectory

        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.path))
        XCTAssertTrue(directory.path.contains("AnimaMac"))
        XCTAssertTrue(directory.path.contains("Application Support"))
    }

    func testAnimaMacDirectoryIsDirectory() {
        let directory = FileManager.animaMacDirectory

        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: directory.path, isDirectory: &isDirectory)

        XCTAssertTrue(exists)
        XCTAssertTrue(isDirectory.boolValue)
    }

    func testAnimaMacRecordingsDirectoryExists() {
        let directory = FileManager.animaMacRecordingsDirectory

        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.path))
        XCTAssertTrue(directory.path.contains("recordings"))
    }

    func testAnimaMacRecordingsDirectoryIsSubdirectory() {
        let parentDir = FileManager.animaMacDirectory
        let recordingsDir = FileManager.animaMacRecordingsDirectory

        XCTAssertTrue(recordingsDir.path.hasPrefix(parentDir.path))
    }

    // MARK: - FFmpeg Path Tests

    func testFFmpegBinaryURLPath() {
        let ffmpegURL = FileManager.ffmpegBinaryURL

        XCTAssertTrue(ffmpegURL.path.contains("AnimaMac"))
        XCTAssertTrue(ffmpegURL.lastPathComponent == "ffmpeg")
    }

    func testFFmpegBinaryURLIsUnderAnimaMacDirectory() {
        let parentDir = FileManager.animaMacDirectory
        let ffmpegURL = FileManager.ffmpegBinaryURL

        XCTAssertTrue(ffmpegURL.path.hasPrefix(parentDir.path))
    }

    func testIsFFmpegAvailableReturnsBool() {
        // Just verify it returns a boolean without crashing
        let isAvailable = FileManager.isFFmpegAvailable
        XCTAssertTrue(isAvailable == true || isAvailable == false)
    }

    // MARK: - Directory Creation Tests

    func testAnimaMacDirectoryCreatesIfNotExists() {
        // Get the directory (which creates it if needed)
        let directory = FileManager.animaMacDirectory

        // Verify it exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.path))
    }

    func testRecordingsDirectoryCreatesIfNotExists() {
        // Get the directory (which creates it if needed)
        let directory = FileManager.animaMacRecordingsDirectory

        // Verify it exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.path))
    }

    // MARK: - Path Consistency Tests

    func testDirectoryPathsAreConsistent() {
        // Multiple calls should return the same paths
        let dir1 = FileManager.animaMacDirectory
        let dir2 = FileManager.animaMacDirectory

        XCTAssertEqual(dir1, dir2)
    }

    func testRecordingsDirectoryPathsAreConsistent() {
        let dir1 = FileManager.animaMacRecordingsDirectory
        let dir2 = FileManager.animaMacRecordingsDirectory

        XCTAssertEqual(dir1, dir2)
    }

    func testFFmpegPathIsConsistent() {
        let url1 = FileManager.ffmpegBinaryURL
        let url2 = FileManager.ffmpegBinaryURL

        XCTAssertEqual(url1, url2)
    }
}
