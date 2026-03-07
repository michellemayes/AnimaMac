import XCTest
@testable import AnimaMacCore

final class GIFExporterTests: XCTestCase {

    var exporter: GIFExporter!

    override func setUp() {
        super.setUp()
        exporter = GIFExporter()
    }

    override func tearDown() {
        exporter = nil
        super.tearDown()
    }

    // MARK: - Filter Chain Tests

    func testBuildFilterChainSmallPreset() {
        var settings = ExportSettings()
        settings.preset = .small

        let filterChain = exporter.buildFilterChain(settings: settings)

        // Should contain fps=10 (small preset fps)
        XCTAssertTrue(filterChain.contains("fps=10"))
        // Should contain scale=480 (small preset maxWidth)
        XCTAssertTrue(filterChain.contains("scale=480"))
        // Should contain max_colors=128 (small preset)
        XCTAssertTrue(filterChain.contains("max_colors=128"))
        // Should contain bayer dithering (small preset)
        XCTAssertTrue(filterChain.contains("dither=bayer"))
    }

    func testBuildFilterChainMediumPreset() {
        var settings = ExportSettings()
        settings.preset = .medium

        let filterChain = exporter.buildFilterChain(settings: settings)

        XCTAssertTrue(filterChain.contains("fps=15"), "Expected fps=15 in filter chain")
        XCTAssertTrue(filterChain.contains("scale=640"), "Expected scale=640 in filter chain")
        XCTAssertTrue(filterChain.contains("max_colors=256"), "Expected max_colors=256 in filter chain")
        // Check for sierra2 dithering - the ffmpegValue for .sierra2
        XCTAssertTrue(filterChain.contains("dither=\(DitheringMode.sierra2.ffmpegValue)"),
                      "Expected dither=\(DitheringMode.sierra2.ffmpegValue) in filter chain: \(filterChain)")
    }

    func testBuildFilterChainLargePreset() {
        var settings = ExportSettings()
        settings.preset = .large

        let filterChain = exporter.buildFilterChain(settings: settings)

        XCTAssertTrue(filterChain.contains("fps=20"))
        XCTAssertTrue(filterChain.contains("scale=1280"))
        XCTAssertTrue(filterChain.contains("dither=floyd_steinberg"))
    }

    func testBuildFilterChainOriginalPreset() {
        var settings = ExportSettings()
        settings.preset = .original

        let filterChain = exporter.buildFilterChain(settings: settings)

        XCTAssertTrue(filterChain.contains("fps=30"))
        XCTAssertTrue(filterChain.contains("scale=9999"))
    }

    func testBuildFilterChainCustomSettings() {
        var settings = ExportSettings()
        settings.customFPS = 24
        settings.customMaxWidth = 800
        settings.customMaxColors = 64
        settings.customDithering = DitheringMode.none

        let filterChain = exporter.buildFilterChain(settings: settings)

        XCTAssertTrue(filterChain.contains("fps=24"))
        XCTAssertTrue(filterChain.contains("scale=800"))
        XCTAssertTrue(filterChain.contains("max_colors=64"))
        XCTAssertTrue(filterChain.contains("dither=none"))
    }

    // MARK: - Filter Chain Structure

    func testFilterChainContainsInputStreamSelector() {
        let settings = ExportSettings()
        let filterChain = exporter.buildFilterChain(settings: settings)

        XCTAssertTrue(filterChain.hasPrefix("[0:v]"))
    }

    func testFilterChainContainsLanczosScaling() {
        let settings = ExportSettings()
        let filterChain = exporter.buildFilterChain(settings: settings)

        XCTAssertTrue(filterChain.contains("flags=lanczos"))
    }

    func testFilterChainContainsSplit() {
        let settings = ExportSettings()
        let filterChain = exporter.buildFilterChain(settings: settings)

        XCTAssertTrue(filterChain.contains("split[s0][s1]"))
    }

    func testFilterChainContainsPaletteGen() {
        let settings = ExportSettings()
        let filterChain = exporter.buildFilterChain(settings: settings)

        XCTAssertTrue(filterChain.contains("palettegen"))
        XCTAssertTrue(filterChain.contains("stats_mode=diff"))
    }

    func testFilterChainContainsPaletteUse() {
        let settings = ExportSettings()
        let filterChain = exporter.buildFilterChain(settings: settings)

        XCTAssertTrue(filterChain.contains("paletteuse"))
        XCTAssertTrue(filterChain.contains("diff_mode=rectangle"))
    }

    func testFilterChainUsesEvenDimensionScale() {
        let settings = ExportSettings()
        let filterChain = exporter.buildFilterChain(settings: settings)

        // Should use -2 for auto height to ensure even dimensions
        XCTAssertTrue(filterChain.contains(":-2:"))
    }

    // MARK: - Filter Chain Format Validation

    func testFilterChainIsValidFFmpegFormat() {
        let settings = ExportSettings()
        let filterChain = exporter.buildFilterChain(settings: settings)

        // Should have proper stream references
        XCTAssertTrue(filterChain.contains("[s0]"))
        XCTAssertTrue(filterChain.contains("[s1]"))
        XCTAssertTrue(filterChain.contains("[p]"))

        // Should have proper filter separators
        XCTAssertTrue(filterChain.contains(";"))
    }

    // MARK: - Comprehensive Filter Chain Tests

    func testFilterChainAllDitheringModes() {
        for ditheringMode in DitheringMode.allCases {
            var settings = ExportSettings()
            settings.customDithering = ditheringMode

            let filterChain = exporter.buildFilterChain(settings: settings)

            XCTAssertTrue(
                filterChain.contains("dither=\(ditheringMode.ffmpegValue)"),
                "Filter chain should contain dithering mode \(ditheringMode)"
            )
        }
    }

    func testFilterChainAllPresets() {
        for preset in ExportPreset.allCases {
            var settings = ExportSettings()
            settings.preset = preset

            let filterChain = exporter.buildFilterChain(settings: settings)

            // Verify FPS matches preset
            XCTAssertTrue(filterChain.contains("fps=\(settings.fps)"))
            // Verify max width matches preset
            XCTAssertTrue(filterChain.contains("scale=\(settings.maxWidth)"))
            // Verify max colors matches preset
            XCTAssertTrue(filterChain.contains("max_colors=\(settings.maxColors)"))
        }
    }

    func testFilterChainWithCustomFPS() {
        var settings = ExportSettings()
        settings.customFPS = 25

        let filterChain = exporter.buildFilterChain(settings: settings)

        XCTAssertTrue(filterChain.contains("fps=25"))
    }

    func testFilterChainWithCustomMaxWidth() {
        var settings = ExportSettings()
        settings.customMaxWidth = 800

        let filterChain = exporter.buildFilterChain(settings: settings)

        XCTAssertTrue(filterChain.contains("scale=800"))
    }

    func testFilterChainWithCustomMaxColors() {
        var settings = ExportSettings()
        settings.customMaxColors = 64

        let filterChain = exporter.buildFilterChain(settings: settings)

        XCTAssertTrue(filterChain.contains("max_colors=64"))
    }

    func testFilterChainStructureOrder() {
        let settings = ExportSettings()
        let filterChain = exporter.buildFilterChain(settings: settings)

        // Verify the structure follows the correct order
        let fpsIndex = filterChain.range(of: "fps=")?.lowerBound
        let scaleIndex = filterChain.range(of: "scale=")?.lowerBound
        let splitIndex = filterChain.range(of: "split")?.lowerBound
        let palettegenIndex = filterChain.range(of: "palettegen")?.lowerBound
        let paletteuseIndex = filterChain.range(of: "paletteuse")?.lowerBound

        XCTAssertNotNil(fpsIndex)
        XCTAssertNotNil(scaleIndex)
        XCTAssertNotNil(splitIndex)
        XCTAssertNotNil(palettegenIndex)
        XCTAssertNotNil(paletteuseIndex)

        // Verify order: fps < scale < split < palettegen < paletteuse
        XCTAssertLessThan(fpsIndex!, scaleIndex!)
        XCTAssertLessThan(scaleIndex!, splitIndex!)
        XCTAssertLessThan(splitIndex!, palettegenIndex!)
        XCTAssertLessThan(palettegenIndex!, paletteuseIndex!)
    }

    func testFilterChainWithMinimalSettings() {
        var settings = ExportSettings()
        settings.preset = .small
        settings.customFPS = 5
        settings.customMaxColors = 32

        let filterChain = exporter.buildFilterChain(settings: settings)

        XCTAssertTrue(filterChain.contains("fps=5"))
        XCTAssertTrue(filterChain.contains("max_colors=32"))
    }

    func testFilterChainWithMaximalSettings() {
        var settings = ExportSettings()
        settings.preset = .original
        settings.customFPS = 60
        settings.customMaxColors = 256

        let filterChain = exporter.buildFilterChain(settings: settings)

        XCTAssertTrue(filterChain.contains("fps=60"))
        XCTAssertTrue(filterChain.contains("max_colors=256"))
    }

    // MARK: - Exporter Protocol Tests

    func testGIFExporterConformsToProtocol() {
        let exporter: GIFExporterProtocol = GIFExporter()
        XCTAssertNotNil(exporter)
    }

    func testBuildFilterChainIsReproducible() {
        let settings = ExportSettings()

        let chain1 = exporter.buildFilterChain(settings: settings)
        let chain2 = exporter.buildFilterChain(settings: settings)

        XCTAssertEqual(chain1, chain2)
    }

    func testBuildFilterChainDifferentSettingsProduceDifferentChains() {
        var settings1 = ExportSettings()
        settings1.preset = .small

        var settings2 = ExportSettings()
        settings2.preset = .large

        let chain1 = exporter.buildFilterChain(settings: settings1)
        let chain2 = exporter.buildFilterChain(settings: settings2)

        XCTAssertNotEqual(chain1, chain2)
    }
}
