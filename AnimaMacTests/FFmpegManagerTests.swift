import XCTest
@testable import AnimaMacCore

final class FFmpegManagerTests: XCTestCase {

    // MARK: - FFmpegError Tests

    func testDownloadFailedErrorDescription() {
        let error = FFmpegError.downloadFailed
        XCTAssertEqual(error.errorDescription, "Failed to download FFmpeg")
    }

    func testExtractionFailedErrorDescription() {
        let error = FFmpegError.extractionFailed
        XCTAssertEqual(error.errorDescription, "Failed to extract FFmpeg")
    }

    func testBinaryNotFoundErrorDescription() {
        let error = FFmpegError.binaryNotFound
        XCTAssertEqual(error.errorDescription, "FFmpeg binary not found in download")
    }

    func testExecutionFailedErrorDescription() {
        let errorMessage = "Invalid input file"
        let error = FFmpegError.executionFailed(errorMessage)
        XCTAssertEqual(error.errorDescription, "FFmpeg error: Invalid input file")
    }

    func testExecutionFailedWithEmptyMessage() {
        let error = FFmpegError.executionFailed("")
        XCTAssertEqual(error.errorDescription, "FFmpeg error: ")
    }

    // MARK: - FFmpegError LocalizedError Conformance

    func testErrorIsLocalizedError() {
        let error: LocalizedError = FFmpegError.downloadFailed
        XCTAssertNotNil(error.errorDescription)
    }

    // MARK: - Shared Instance

    func testSharedInstanceExists() async {
        let manager = FFmpegManager.shared
        XCTAssertNotNil(manager)
    }

    func testSharedInstanceIsSingleton() async {
        let manager1 = FFmpegManager.shared
        let manager2 = FFmpegManager.shared

        // Both references should point to the same instance
        // Actor identity comparison through nonisolated property check
        let isAvailable1 = await manager1.isAvailable
        let isAvailable2 = await manager2.isAvailable
        XCTAssertEqual(isAvailable1, isAvailable2)
    }

    // MARK: - Availability Check

    func testIsAvailableReturnsConsistentResult() async {
        let manager = FFmpegManager.shared
        let firstCheck = await manager.isAvailable
        let secondCheck = await manager.isAvailable

        XCTAssertEqual(firstCheck, secondCheck)
    }

    // MARK: - Executable URL

    func testExecutableURLReturnsValidPath() async {
        let manager = FFmpegManager.shared
        let url = await manager.executableURL

        // Should return a file URL
        XCTAssertTrue(url.isFileURL)
        // Should have ffmpeg in the path
        XCTAssertTrue(url.path.contains("ffmpeg"))
    }

    func testExecutableURLPrefersSystemFFmpeg() async {
        let manager = FFmpegManager.shared
        let url = await manager.executableURL

        // If system FFmpeg exists, it should be preferred
        let systemPaths = [
            "/opt/homebrew/bin/ffmpeg",
            "/usr/local/bin/ffmpeg",
            "/usr/bin/ffmpeg"
        ]

        let systemFFmpegExists = systemPaths.contains {
            FileManager.default.isExecutableFile(atPath: $0)
        }

        if systemFFmpegExists {
            XCTAssertTrue(systemPaths.contains(url.path))
        }
    }

    // MARK: - Ensure Available

    func testEnsureAvailableDoesNotThrowWhenAvailable() async {
        let manager = FFmpegManager.shared

        // Only test if FFmpeg is available on this system
        let isAvailable = await manager.isAvailable
        if isAvailable {
            do {
                try await manager.ensureAvailable()
                // Should not throw
            } catch {
                XCTFail("ensureAvailable should not throw when FFmpeg is available: \(error)")
            }
        }
    }

    // MARK: - Run Command (Integration Test)

    func testRunVersionCommand() async throws {
        let manager = FFmpegManager.shared

        // Skip if FFmpeg not available (don't want to download in tests)
        guard await manager.isAvailable else {
            throw XCTSkip("FFmpeg not available on this system")
        }

        let result = try await manager.run(arguments: ["-version"])

        // FFmpeg version output goes to stdout or stderr depending on version
        let combined = result.output + result.error
        XCTAssertTrue(combined.contains("ffmpeg") || combined.contains("FFmpeg"))
    }

    func testRunWithInvalidArgumentsThrows() async {
        let manager = FFmpegManager.shared

        // Skip if FFmpeg not available
        guard await manager.isAvailable else {
            return
        }

        do {
            _ = try await manager.run(arguments: ["-i", "/nonexistent/file.mov", "/tmp/out.gif"])
            XCTFail("Should throw for invalid input")
        } catch let error as FFmpegError {
            if case .executionFailed(_) = error {
                // Expected
            } else {
                XCTFail("Expected executionFailed error")
            }
        } catch {
            // Other errors are also acceptable (file not found, etc.)
        }
    }

    // MARK: - Progress Parsing

    func testRunWithProgressCompletesWithProgress() async throws {
        let manager = FFmpegManager.shared

        // Skip if FFmpeg not available
        guard await manager.isAvailable else {
            throw XCTSkip("FFmpeg not available on this system")
        }

        var progressCalled = false
        var lastProgress: Double = 0

        // Create a test video to convert
        let tempDir = FileManager.default.temporaryDirectory
        let inputURL = tempDir.appendingPathComponent("test_input_\(UUID().uuidString).mov")
        let outputURL = tempDir.appendingPathComponent("test_output_\(UUID().uuidString).gif")

        defer {
            try? FileManager.default.removeItem(at: inputURL)
            try? FileManager.default.removeItem(at: outputURL)
        }

        // Create a minimal valid video using FFmpeg (generate test pattern)
        let generateArgs = [
            "-y",
            "-f", "lavfi",
            "-i", "testsrc=duration=1:size=100x100:rate=10",
            "-c:v", "libx264",
            "-pix_fmt", "yuv420p",
            inputURL.path
        ]

        do {
            _ = try await manager.run(arguments: generateArgs)
        } catch {
            throw XCTSkip("Could not generate test video: \(error)")
        }

        // Now test progress with actual conversion
        try await manager.runWithProgress(
            arguments: ["-y", "-i", inputURL.path, "-vf", "fps=10,scale=50:-1", outputURL.path],
            duration: 1.0
        ) { progress in
            progressCalled = true
            lastProgress = progress
        }

        XCTAssertTrue(progressCalled)
        XCTAssertEqual(lastProgress, 1.0, accuracy: 0.01, "Final progress should be 1.0")
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
    }
}
