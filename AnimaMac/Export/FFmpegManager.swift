import Foundation

actor FFmpegManager {
    static let shared = FFmpegManager()

    private let binaryURL = FileManager.ffmpegBinaryURL

    // FFmpeg download source (static builds for macOS)
    private let downloadURL = URL(string: "https://evermeet.cx/ffmpeg/getrelease/ffmpeg/zip")!

    var isAvailable: Bool {
        FileManager.default.fileExists(atPath: binaryURL.path)
    }

    // MARK: - Download

    func ensureAvailable() async throws {
        if isAvailable {
            return
        }

        try await downloadFFmpeg()
    }

    private func downloadFFmpeg() async throws {
        print("Downloading FFmpeg...")

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

        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = binaryURL
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
        progressHandler: @escaping (Double) -> Void
    ) async throws {
        try await ensureAvailable()

        let process = Process()
        process.executableURL = binaryURL
        process.arguments = ["-progress", "pipe:1", "-nostats"] + arguments

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        // Read progress output
        outputPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty else { return }

            if let output = String(data: data, encoding: .utf8) {
                // Parse progress from FFmpeg output
                // Format: out_time_ms=1234567
                let lines = output.components(separatedBy: "\n")
                for line in lines {
                    if line.hasPrefix("out_time_ms=") {
                        let timeStr = line.replacingOccurrences(of: "out_time_ms=", with: "")
                        if let timeMs = Double(timeStr) {
                            let progress = min(1.0, timeMs / 1_000_000 / duration)
                            Task { @MainActor in
                                progressHandler(progress)
                            }
                        }
                    }
                }
            }
        }

        try process.run()
        process.waitUntilExit()

        outputPipe.fileHandleForReading.readabilityHandler = nil

        if process.terminationStatus != 0 {
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
            let error = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw FFmpegError.executionFailed(error)
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
