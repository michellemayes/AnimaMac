import Foundation
import AVFoundation

// MARK: - Protocol

@MainActor
protocol GIFExporterProtocol: Sendable {
    func export(
        videoURL: URL,
        to outputURL: URL,
        settings: ExportSettings,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws

    func buildFilterChain(settings: ExportSettings) -> String
}

// MARK: - Implementation

final class GIFExporter: GIFExporterProtocol, Sendable {
    private let ffmpeg = FFmpegManager.shared

    func export(
        videoURL: URL,
        to outputURL: URL,
        settings: ExportSettings,
        progressHandler: @escaping @Sendable (Double) -> Void
    ) async throws {
        print("[GIFExporter] Starting export: \(videoURL.path) -> \(outputURL.path)")

        // Get video duration for progress tracking
        let asset = AVAsset(url: videoURL)
        let duration = try await asset.load(.duration).seconds
        print("[GIFExporter] Video duration: \(duration)s")

        // Build FFmpeg filter chain for high-quality GIF
        let filterChain = buildFilterChain(settings: settings)
        print("[GIFExporter] Filter chain: \(filterChain)")

        let arguments = [
            "-y",  // Overwrite output
            "-i", videoURL.path,
            "-filter_complex", filterChain,
            "-loop", "\(settings.loopCount)",
            outputURL.path
        ]

        print("[GIFExporter] Running FFmpeg with args: \(arguments.joined(separator: " "))")

        do {
            try await ffmpeg.runWithProgress(
                arguments: arguments,
                duration: duration,
                progressHandler: progressHandler
            )
            print("[GIFExporter] Export completed successfully")
        } catch {
            print("[GIFExporter] Export failed: \(error)")
            throw error
        }
    }

    func buildFilterChain(settings: ExportSettings) -> String {
        // Two-pass palette generation for high quality GIFs
        // Input -> fps -> scale -> split -> palettegen + paletteuse

        // Build the filter graph
        // [0:v] is the input video stream
        var filterGraph = "[0:v]fps=\(settings.fps)"

        // Scale with Lanczos for quality (use -2 to ensure even dimensions)
        filterGraph += ",scale=\(settings.maxWidth):-2:flags=lanczos"

        // Split for palette generation
        filterGraph += ",split[s0][s1];"

        // Generate palette from one stream
        filterGraph += "[s0]palettegen=max_colors=\(settings.maxColors):stats_mode=diff[p];"

        // Apply palette to the other stream
        filterGraph += "[s1][p]paletteuse=dither=\(settings.dithering.ffmpegValue):diff_mode=rectangle"

        return filterGraph
    }

    // MARK: - Quick Export (no progress)

    func quickExport(
        videoURL: URL,
        to outputURL: URL,
        settings: ExportSettings
    ) async throws {
        let filterChain = buildFilterChain(settings: settings)

        let arguments = [
            "-y",
            "-i", videoURL.path,
            "-filter_complex", filterChain,
            "-loop", "\(settings.loopCount)",
            outputURL.path
        ]

        _ = try await ffmpeg.run(arguments: arguments)
    }

    // MARK: - Preview Generation

    func generatePreview(
        videoURL: URL,
        at time: TimeInterval = 0,
        size: CGSize = CGSize(width: 200, height: 150)
    ) async throws -> URL {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("png")

        let arguments = [
            "-y",
            "-i", videoURL.path,
            "-ss", String(format: "%.2f", time),
            "-frames:v", "1",
            "-vf", "scale=\(Int(size.width)):-1",
            outputURL.path
        ]

        _ = try await ffmpeg.run(arguments: arguments)
        return outputURL
    }
}
