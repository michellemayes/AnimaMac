import Foundation
import Testing

@testable import AnimaMac

@Suite("GIFExporter Filter Chain")
struct GIFExporterTests {

    let exporter = GIFExporter()

    @Test("Contains FPS from settings")
    func containsFPS() {
        let settings = ExportSettings(preset: .medium)
        let chain = exporter.buildFilterChain(settings: settings)
        #expect(chain.contains("fps=15"))
    }

    @Test("Contains scale with Lanczos")
    func containsScale() {
        let settings = ExportSettings(preset: .small)
        let chain = exporter.buildFilterChain(settings: settings)
        #expect(chain.contains("scale=480:-1:flags=lanczos"))
    }

    @Test("Contains split for two-pass")
    func containsSplit() {
        let chain = exporter.buildFilterChain(settings: ExportSettings())
        #expect(chain.contains("split[s0][s1]"))
    }

    @Test("Contains palettegen with max colors")
    func containsPaletteGen() {
        let settings = ExportSettings(preset: .small)
        let chain = exporter.buildFilterChain(settings: settings)
        #expect(chain.contains("palettegen=max_colors=128"))
    }

    @Test("Contains paletteuse with dithering")
    func containsPaletteUse() {
        let settings = ExportSettings(preset: .medium)
        let chain = exporter.buildFilterChain(settings: settings)
        #expect(chain.contains("paletteuse=dither=sierra2:diff_mode=rectangle"))
    }

    @Test("Uses custom overrides")
    func usesCustomOverrides() {
        let settings = ExportSettings(
            preset: .small,
            customFPS: 24,
            customMaxWidth: 800,
            customMaxColors: 64,
            customDithering: .floydSteinberg
        )
        let chain = exporter.buildFilterChain(settings: settings)
        #expect(chain.contains("fps=24"))
        #expect(chain.contains("scale=800:-1"))
        #expect(chain.contains("max_colors=64"))
        #expect(chain.contains("dither=floyd_steinberg"))
    }

    @Test("Has 5 semicolon-separated filters")
    func fiveFilterParts() {
        let chain = exporter.buildFilterChain(settings: ExportSettings())
        let parts = chain.components(separatedBy: ";")
        #expect(parts.count == 5)
    }

    @Test("Correct for all presets", arguments: ExportPreset.allCases)
    func allPresets(preset: ExportPreset) {
        let settings = ExportSettings(preset: preset)
        let chain = exporter.buildFilterChain(settings: settings)
        #expect(chain.contains("fps=\(preset.fps)"))
        #expect(chain.contains("scale=\(preset.maxWidth):-1"))
        #expect(chain.contains("max_colors=\(preset.maxColors)"))
        #expect(chain.contains("dither=\(preset.dithering.ffmpegValue)"))
    }
}
