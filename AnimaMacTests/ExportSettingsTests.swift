import XCTest
@testable import AnimaMacCore

final class ExportSettingsTests: XCTestCase {

    // MARK: - Default Values

    func testDefaultSettings() {
        let settings = ExportSettings()

        XCTAssertEqual(settings.preset, .medium)
        XCTAssertNil(settings.customFPS)
        XCTAssertNil(settings.customMaxWidth)
        XCTAssertNil(settings.customMaxColors)
        XCTAssertNil(settings.customDithering)
        XCTAssertEqual(settings.loopCount, 0)
    }

    func testDefaultValuesFromPreset() {
        let settings = ExportSettings()

        // Medium preset defaults
        XCTAssertEqual(settings.fps, 15)
        XCTAssertEqual(settings.maxWidth, 640)
        XCTAssertEqual(settings.maxColors, 256)
        XCTAssertEqual(settings.dithering, .sierra2)
    }

    // MARK: - Preset Values

    func testSmallPreset() {
        var settings = ExportSettings()
        settings.preset = .small

        XCTAssertEqual(settings.fps, 10)
        XCTAssertEqual(settings.maxWidth, 480)
        XCTAssertEqual(settings.maxColors, 128)
        XCTAssertEqual(settings.dithering, .bayer)
    }

    func testMediumPreset() {
        var settings = ExportSettings()
        settings.preset = .medium

        XCTAssertEqual(settings.fps, 15)
        XCTAssertEqual(settings.maxWidth, 640)
        XCTAssertEqual(settings.maxColors, 256)
        XCTAssertEqual(settings.dithering, .sierra2)
    }

    func testLargePreset() {
        var settings = ExportSettings()
        settings.preset = .large

        XCTAssertEqual(settings.fps, 20)
        XCTAssertEqual(settings.maxWidth, 1280)
        XCTAssertEqual(settings.maxColors, 256)
        XCTAssertEqual(settings.dithering, .floydSteinberg)
    }

    func testOriginalPreset() {
        var settings = ExportSettings()
        settings.preset = .original

        XCTAssertEqual(settings.fps, 30)
        XCTAssertEqual(settings.maxWidth, 9999)
        XCTAssertEqual(settings.maxColors, 256)
        XCTAssertEqual(settings.dithering, .floydSteinberg)
    }

    // MARK: - Custom Values Override Preset

    func testCustomFPSOverridesPreset() {
        var settings = ExportSettings()
        settings.preset = .small  // fps = 10
        settings.customFPS = 25

        XCTAssertEqual(settings.fps, 25)
    }

    func testCustomMaxWidthOverridesPreset() {
        var settings = ExportSettings()
        settings.preset = .small  // maxWidth = 480
        settings.customMaxWidth = 800

        XCTAssertEqual(settings.maxWidth, 800)
    }

    func testCustomMaxColorsOverridesPreset() {
        var settings = ExportSettings()
        settings.preset = .small  // maxColors = 128
        settings.customMaxColors = 64

        XCTAssertEqual(settings.maxColors, 64)
    }

    func testCustomDitheringOverridesPreset() {
        var settings = ExportSettings()
        settings.preset = .small  // dithering = .bayer
        settings.customDithering = .floydSteinberg

        XCTAssertEqual(settings.dithering, .floydSteinberg)
    }

    // MARK: - Codable

    func testEncodeDecode() throws {
        var settings = ExportSettings()
        settings.preset = .large
        settings.customFPS = 24
        settings.loopCount = 3

        let encoder = JSONEncoder()
        let data = try encoder.encode(settings)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ExportSettings.self, from: data)

        XCTAssertEqual(decoded.preset, .large)
        XCTAssertEqual(decoded.customFPS, 24)
        XCTAssertEqual(decoded.loopCount, 3)
        XCTAssertEqual(decoded.fps, 24)  // Custom overrides preset
    }

    // MARK: - Equatable

    func testEquality() {
        let settings1 = ExportSettings()
        let settings2 = ExportSettings()

        XCTAssertEqual(settings1, settings2)
    }

    func testInequality() {
        var settings1 = ExportSettings()
        var settings2 = ExportSettings()
        settings2.preset = .large

        XCTAssertNotEqual(settings1, settings2)
    }
}

// MARK: - ExportPreset Tests

final class ExportPresetTests: XCTestCase {

    func testAllCases() {
        let allCases = ExportPreset.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.small))
        XCTAssertTrue(allCases.contains(.medium))
        XCTAssertTrue(allCases.contains(.large))
        XCTAssertTrue(allCases.contains(.original))
    }

    func testDisplayNames() {
        XCTAssertEqual(ExportPreset.small.displayName, "Small (Fast upload)")
        XCTAssertEqual(ExportPreset.medium.displayName, "Medium (Balanced)")
        XCTAssertEqual(ExportPreset.large.displayName, "Large (High quality)")
        XCTAssertEqual(ExportPreset.original.displayName, "Original (Maximum quality)")
    }

    func testIdentifiable() {
        XCTAssertEqual(ExportPreset.small.id, "small")
        XCTAssertEqual(ExportPreset.medium.id, "medium")
        XCTAssertEqual(ExportPreset.large.id, "large")
        XCTAssertEqual(ExportPreset.original.id, "original")
    }
}

// MARK: - DitheringMode Tests

final class DitheringModeTests: XCTestCase {

    func testAllCases() {
        let allCases = DitheringMode.allCases
        XCTAssertEqual(allCases.count, 5)
    }

    func testFFmpegValues() {
        XCTAssertEqual(DitheringMode.none.ffmpegValue, "none")
        XCTAssertEqual(DitheringMode.bayer.ffmpegValue, "bayer")
        XCTAssertEqual(DitheringMode.sierra2.ffmpegValue, "sierra2")
        XCTAssertEqual(DitheringMode.sierra2_4a.ffmpegValue, "sierra2_4a")
        XCTAssertEqual(DitheringMode.floydSteinberg.ffmpegValue, "floyd_steinberg")
    }

    func testDisplayNames() {
        XCTAssertEqual(DitheringMode.none.displayName, "None (sharp edges)")
        XCTAssertEqual(DitheringMode.bayer.displayName, "Bayer (ordered)")
        XCTAssertEqual(DitheringMode.sierra2.displayName, "Sierra-2")
        XCTAssertEqual(DitheringMode.sierra2_4a.displayName, "Sierra-2-4A (fast)")
        XCTAssertEqual(DitheringMode.floydSteinberg.displayName, "Floyd-Steinberg (smooth)")
    }

    func testIdentifiable() {
        XCTAssertEqual(DitheringMode.floydSteinberg.id, "floydSteinberg")
    }
}
