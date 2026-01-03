import Foundation
import AVFoundation

final class GIFExporter {
    private let ffmpeg = FFmpegManager.shared

    func export(
        videoURL: URL,
        to outputURL: URL,
        settings: ExportSettings,
        progressHandler: @escaping (Double) -> Void
    ) async throws {
        // Get video duration for progress tracking
        let asset = AVAsset(url: videoURL)
        let duration = try await asset.load(.duration).seconds

        // Build FFmpeg filter chain for high-quality GIF
        let filterChain = buildFilterChain(settings: settings)

        let arguments = [
            "-y",  // Overwrite output
            "-i", videoURL.path,
            "-vf", filterChain,
            "-loop", "\(settings.loopCount)",
            outputURL.path
        ]

        try await ffmpeg.runWithProgress(
            arguments: arguments,
            duration: duration,
            progressHandler: progressHandler
        )
    }

    private func buildFilterChain(settings: ExportSettings) -> String {
        // Two-pass palette generation for high quality GIFs
        // fps -> scale -> split -> palettegen -> paletteuse

        var filters: [String] = []

        // Frame rate
        filters.append("fps=\(settings.fps)")

        // Scale with Lanczos for quality
        filters.append("scale=\(settings.maxWidth):-1:flags=lanczos")

        // Split stream for palette generation
        filters.append("split[s0][s1]")

        // Generate palette
        filters.append("[s0]palettegen=max_colors=\(settings.maxColors):stats_mode=diff[p]")

        // Apply palette with dithering
        filters.append("[s1][p]paletteuse=dither=\(settings.dithering.ffmpegValue):diff_mode=rectangle")

        return filters.joined(separator: ";")
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
            "-vf", filterChain,
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
