import Foundation
import Testing

@testable import AnimaMacCore

@Suite("ExportSettings")
struct ExportSettingsTests {

    @Test("Default preset is medium")
    func defaultPreset() {
        let settings = ExportSettings()
        #expect(settings.preset == .medium)
    }

    @Test("Default loop count is 0 (infinite)")
    func defaultLoopCount() {
        let settings = ExportSettings()
        #expect(settings.loopCount == 0)
    }

    @Test("Custom overrides are nil by default")
    func defaultCustomOverrides() {
        let settings = ExportSettings()
        #expect(settings.customFPS == nil)
        #expect(settings.customMaxWidth == nil)
        #expect(settings.customMaxColors == nil)
        #expect(settings.customDithering == nil)
    }

    @Test("FPS falls back to preset", arguments: ExportPreset.allCases)
    func fpsUsesPreset(preset: ExportPreset) {
        let settings = ExportSettings(preset: preset)
        #expect(settings.fps == preset.fps)
    }

    @Test("MaxWidth falls back to preset", arguments: ExportPreset.allCases)
    func maxWidthUsesPreset(preset: ExportPreset) {
        let settings = ExportSettings(preset: preset)
        #expect(settings.maxWidth == preset.maxWidth)
    }

    @Test("MaxColors falls back to preset", arguments: ExportPreset.allCases)
    func maxColorsUsesPreset(preset: ExportPreset) {
        let settings = ExportSettings(preset: preset)
        #expect(settings.maxColors == preset.maxColors)
    }

    @Test("Dithering falls back to preset", arguments: ExportPreset.allCases)
    func ditheringUsesPreset(preset: ExportPreset) {
        let settings = ExportSettings(preset: preset)
        #expect(settings.dithering == preset.dithering)
    }

    @Test("Custom FPS overrides preset")
    func customFPSOverrides() {
        let settings = ExportSettings(preset: .small, customFPS: 24)
        #expect(settings.fps == 24)
    }

    @Test("Custom max width overrides preset")
    func customMaxWidthOverrides() {
        let settings = ExportSettings(preset: .small, customMaxWidth: 800)
        #expect(settings.maxWidth == 800)
    }

    @Test("Custom max colors overrides preset")
    func customMaxColorsOverrides() {
        let settings = ExportSettings(preset: .large, customMaxColors: 64)
        #expect(settings.maxColors == 64)
    }

    @Test("Custom dithering overrides preset")
    func customDitheringOverrides() {
        let settings = ExportSettings(preset: .small, customDithering: DitheringMode.none)
        #expect(settings.dithering == DitheringMode.none)
    }

    @Test("Codable round-trip")
    func codableRoundTrip() throws {
        var settings = ExportSettings(preset: .large)
        settings.customFPS = 24
        settings.loopCount = 3
        let data = try JSONEncoder().encode(settings)
        let decoded = try JSONDecoder().decode(ExportSettings.self, from: data)
        #expect(settings == decoded)
    }

    @Test("Equatable")
    func equatable() {
        #expect(ExportSettings(preset: .medium) == ExportSettings(preset: .medium))
        #expect(ExportSettings(preset: .small) != ExportSettings(preset: .large))
    }
}

@Suite("ExportPreset")
struct ExportPresetTests {

    @Test("Has 4 cases")
    func allCases() {
        #expect(ExportPreset.allCases.count == 4)
    }

    @Test("ID equals rawValue", arguments: ExportPreset.allCases)
    func identifiable(preset: ExportPreset) {
        #expect(preset.id == preset.rawValue)
    }

    @Test("Display names are non-empty", arguments: ExportPreset.allCases)
    func displayNames(preset: ExportPreset) {
        #expect(!preset.displayName.isEmpty)
    }

    @Test("FPS values")
    func fpsValues() {
        #expect(ExportPreset.small.fps == 10)
        #expect(ExportPreset.medium.fps == 15)
        #expect(ExportPreset.large.fps == 20)
        #expect(ExportPreset.original.fps == 30)
    }

    @Test("Max width values")
    func maxWidthValues() {
        #expect(ExportPreset.small.maxWidth == 480)
        #expect(ExportPreset.medium.maxWidth == 640)
        #expect(ExportPreset.large.maxWidth == 1280)
        #expect(ExportPreset.original.maxWidth == 9999)
    }

    @Test("Max colors values")
    func maxColorsValues() {
        #expect(ExportPreset.small.maxColors == 128)
        #expect(ExportPreset.medium.maxColors == 256)
        #expect(ExportPreset.large.maxColors == 256)
        #expect(ExportPreset.original.maxColors == 256)
    }

    @Test("Dithering values")
    func ditheringValues() {
        #expect(ExportPreset.small.dithering == .bayer)
        #expect(ExportPreset.medium.dithering == .sierra2)
        #expect(ExportPreset.large.dithering == .floydSteinberg)
        #expect(ExportPreset.original.dithering == .floydSteinberg)
    }

    @Test("Codable round-trip", arguments: ExportPreset.allCases)
    func codable(preset: ExportPreset) throws {
        let data = try JSONEncoder().encode(preset)
        let decoded = try JSONDecoder().decode(ExportPreset.self, from: data)
        #expect(preset == decoded)
    }
}

@Suite("DitheringMode")
struct DitheringModeTests {

    @Test("Has 5 cases")
    func allCases() {
        #expect(DitheringMode.allCases.count == 5)
    }

    @Test("ID equals rawValue", arguments: DitheringMode.allCases)
    func identifiable(mode: DitheringMode) {
        #expect(mode.id == mode.rawValue)
    }

    @Test("Display names are non-empty", arguments: DitheringMode.allCases)
    func displayNames(mode: DitheringMode) {
        #expect(!mode.displayName.isEmpty)
    }

    @Test("FFmpeg values")
    func ffmpegValues() {
        #expect(DitheringMode.none.ffmpegValue == "none")
        #expect(DitheringMode.bayer.ffmpegValue == "bayer")
        #expect(DitheringMode.sierra2.ffmpegValue == "sierra2")
        #expect(DitheringMode.sierra2_4a.ffmpegValue == "sierra2_4a")
        #expect(DitheringMode.floydSteinberg.ffmpegValue == "floyd_steinberg")
    }

    @Test("Codable round-trip", arguments: DitheringMode.allCases)
    func codable(mode: DitheringMode) throws {
        let data = try JSONEncoder().encode(mode)
        let decoded = try JSONDecoder().decode(DitheringMode.self, from: data)
        #expect(mode == decoded)
    }
}
