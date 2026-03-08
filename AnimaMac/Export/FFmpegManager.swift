import Foundation

actor FFmpegManager {
    static let shared = FFmpegManager()

    private let binaryURL = FileManager.ffmpegBinaryURL

    // System FFmpeg locations (Homebrew)
    private let systemFFmpegPaths = [
        "/opt/homebrew/bin/ffmpeg",  // ARM64 Homebrew
        "/usr/local/bin/ffmpeg",      // Intel Homebrew
        "/usr/bin/ffmpeg"             // System (unlikely)
    ]

    // FFmpeg download sources by architecture
    private var downloadURL: URL {
        #if arch(arm64)
        // ARM64 static build
        return URL(string: "https://www.osxexperts.net/ffmpeg7arm.zip")!
        #else
        // Intel static build
        return URL(string: "https://evermeet.cx/ffmpeg/getrelease/ffmpeg/zip")!
        #endif
    }

    /// Returns the path to use for FFmpeg execution
    var executableURL: URL {
        // Prefer system FFmpeg if available
        for path in systemFFmpegPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return URL(fileURLWithPath: path)
            }
        }
        return binaryURL
    }

    var isAvailable: Bool {
        // Check system FFmpeg first
        for path in systemFFmpegPaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                return true
            }
        }
        // Then check bundled FFmpeg
        return FileManager.default.fileExists(atPath: binaryURL.path)
    }

    // MARK: - Download

    func ensureAvailable() async throws {
        if isAvailable {
            return
        }

        try await downloadFFmpeg()
    }

    private func downloadFFmpeg() async throws {
        #if arch(arm64)
        print("Downloading FFmpeg for Apple Silicon...")
        #else
        print("Downloading FFmpeg for Intel...")
        #endif

        // Download zip file
        let (tempZipURL, _) = try await URLSession.shared.download(from: downloadURL)

        // Create temp directory for extraction
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? FileManager.default.removeItem(at: tempDir)
            try? FileManager.default.removeItem(at: tempZipURL)
        }

        // Unzip using ditto (macOS built-in)
        let unzipProcess = Process()
        unzipProcess.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        unzipProcess.arguments = ["-xk", tempZipURL.path, tempDir.path]

        try unzipProcess.run()
        unzipProcess.waitUntilExit()

        guard unzipProcess.terminationStatus == 0 else {
            throw FFmpegError.extractionFailed
        }

        // Find the ffmpeg binary in extracted contents
        let enumerator = FileManager.default.enumerator(at: tempDir, includingPropertiesForKeys: nil)
        var foundBinary: URL?

        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.lastPathComponent == "ffmpeg" {
                foundBinary = fileURL
                break
            }
        }

        guard let sourceBinary = foundBinary else {
            throw FFmpegError.binaryNotFound
        }

        // Move to app support directory
        try FileManager.default.moveItem(at: sourceBinary, to: binaryURL)

        // Make executable
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: binaryURL.path
        )

        print("FFmpeg installed successfully at \(binaryURL.path)")
    }

    // MARK: - Execution

    func run(arguments: [String]) async throws -> (output: String, error: String) {
        try await ensureAvailable()

        let ffmpegPath = executableURL
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = ffmpegPath
            process.arguments = arguments

            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            do {
                try process.run()
                process.waitUntilExit()

                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

                let output = String(data: outputData, encoding: .utf8) ?? ""
                let error = String(data: errorData, encoding: .utf8) ?? ""

                if process.terminationStatus != 0 {
                    continuation.resume(throwing: FFmpegError.executionFailed(error))
                } else {
                    continuation.resume(returning: (output, error))
                }
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    func runWithProgress(
        arguments: [String],
        duration: TimeInterval,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws {
        try await ensureAvailable()

        let ffmpegPath = executableURL

        print("[FFmpeg] Starting with args: \(arguments.joined(separator: " "))")

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let process = Process()
            process.executableURL = ffmpegPath
            process.arguments = arguments

            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            // Accumulate stderr for error reporting and progress parsing
            nonisolated(unsafe) var stderrBuffer = ""
            nonisolated(unsafe) var lastProgress: Double = 0

            errorPipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty else { return }

                guard let output = String(data: data, encoding: .utf8) else { return }
                stderrBuffer += output

                // Parse time from FFmpeg stderr output
                // Format: frame=  123 fps= 30 q=28.0 size=    1234kB time=00:00:05.00 ...
                // Use the buffer to handle data split across reads
                let pattern = "time=(-?\\d{2}:\\d{2}:\\d{2}\\.\\d{2})"
                guard let regex = try? NSRegularExpression(pattern: pattern),
                      let match = regex.matches(in: stderrBuffer, range: NSRange(stderrBuffer.startIndex..., in: stderrBuffer)).last,
                      let timeRange = Range(match.range(at: 1), in: stderrBuffer) else { return }

                let timeStr = String(stderrBuffer[timeRange])
                let components = timeStr.split(separator: ":")
                guard components.count == 3,
                      let hours = Double(components[0]),
                      let minutes = Double(components[1]),
                      let seconds = Double(components[2]),
                      duration > 0 else { return }

                let currentTime = hours * 3600 + minutes * 60 + seconds
                guard currentTime >= 0 else { return }
                let progress = min(0.99, currentTime / duration)
                if progress > lastProgress {
                    lastProgress = progress
                    Task { @MainActor in
                        progressHandler(progress)
                    }
                }
            }

            process.terminationHandler = { process in
                errorPipe.fileHandleForReading.readabilityHandler = nil

                let exitCode = process.terminationStatus
                print("[FFmpeg] Exited with code: \(exitCode)")

                if exitCode != 0 {
                    // Read any remaining stderr data
                    let remaining = errorPipe.fileHandleForReading.readDataToEndOfFile()
                    if let str = String(data: remaining, encoding: .utf8) {
                        stderrBuffer += str
                    }
                    print("[FFmpeg] Error output: \(stderrBuffer)")
                    continuation.resume(throwing: FFmpegError.executionFailed(stderrBuffer))
                } else {
                    Task { @MainActor in
                        progressHandler(1.0)
                    }
                    continuation.resume()
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}

// MARK: - Errors

enum FFmpegError: LocalizedError {
    case downloadFailed
    case extractionFailed
    case binaryNotFound
    case executionFailed(String)

    var errorDescription: String? {
        switch self {
        case .downloadFailed:
            return "Failed to download FFmpeg"
        case .extractionFailed:
            return "Failed to extract FFmpeg"
        case .binaryNotFound:
            return "FFmpeg binary not found in download"
        case .executionFailed(let message):
            return "FFmpeg error: \(message)"
        }
    }
}
