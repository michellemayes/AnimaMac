import Foundation
import Testing
@testable import AnimaMac

@Suite("CaptureConfiguration")
struct CaptureConfigurationTests {

    @Test("Default values")
    func defaults() {
        let config = CaptureConfiguration()
        #expect(config.framesPerSecond == 30)
        #expect(config.showsCursor == true)
        #expect(config.capturesMouseClicks == false)
        #expect(config.capturesKeyboardInput == false)
        #expect(config.includeWindowShadow == true)
        #expect(config.quality == .high)
    }

    @Test("Quality display names", arguments: CaptureConfiguration.CaptureQuality.allCases)
    func qualityDisplayNames(quality: CaptureConfiguration.CaptureQuality) {
        #expect(!quality.displayName.isEmpty)
    }

    @Test("Quality scale factors")
    func qualityScaleFactors() {
        #expect(CaptureConfiguration.CaptureQuality.low.scaleFactor == 0.5)
        #expect(CaptureConfiguration.CaptureQuality.medium.scaleFactor == 0.75)
        #expect(CaptureConfiguration.CaptureQuality.high.scaleFactor == 1.0)
    }

    @Test("Has 3 quality levels")
    func qualityCount() {
        #expect(CaptureConfiguration.CaptureQuality.allCases.count == 3)
    }

    @Test("Codable round-trip")
    func codableRoundTrip() throws {
        var config = CaptureConfiguration()
        config.framesPerSecond = 15
        config.showsCursor = false
        config.quality = .low
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(CaptureConfiguration.self, from: data)
        #expect(config == decoded)
    }

    @Test("Equatable")
    func equatable() {
        var a = CaptureConfiguration()
        var b = CaptureConfiguration()
        #expect(a == b)
        a.framesPerSecond = 15
        b.framesPerSecond = 60
        #expect(a != b)
    }

    @Test("Quality codable round-trip", arguments: CaptureConfiguration.CaptureQuality.allCases)
    func qualityCodable(quality: CaptureConfiguration.CaptureQuality) throws {
        let data = try JSONEncoder().encode(quality)
        let decoded = try JSONDecoder().decode(CaptureConfiguration.CaptureQuality.self, from: data)
        #expect(quality == decoded)
    }
}
