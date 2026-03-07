import XCTest
@testable import AnimaMacCore

final class CaptureConfigurationTests: XCTestCase {

    // MARK: - Default Values

    func testDefaultValues() {
        let config = CaptureConfiguration()

        XCTAssertEqual(config.framesPerSecond, 30)
        XCTAssertTrue(config.showsCursor)
        XCTAssertFalse(config.capturesMouseClicks)
        XCTAssertFalse(config.capturesKeyboardInput)
        XCTAssertTrue(config.includeWindowShadow)
        XCTAssertEqual(config.quality, .high)
    }

    // MARK: - Quality Scale Factors

    func testLowQualityScaleFactor() {
        XCTAssertEqual(CaptureConfiguration.CaptureQuality.low.scaleFactor, 0.5)
    }

    func testMediumQualityScaleFactor() {
        XCTAssertEqual(CaptureConfiguration.CaptureQuality.medium.scaleFactor, 0.75)
    }

    func testHighQualityScaleFactor() {
        XCTAssertEqual(CaptureConfiguration.CaptureQuality.high.scaleFactor, 1.0)
    }

    // MARK: - Quality Display Names

    func testQualityDisplayNames() {
        XCTAssertEqual(CaptureConfiguration.CaptureQuality.low.displayName, "Low (smaller file)")
        XCTAssertEqual(CaptureConfiguration.CaptureQuality.medium.displayName, "Medium")
        XCTAssertEqual(CaptureConfiguration.CaptureQuality.high.displayName, "High (best quality)")
    }

    // MARK: - Quality All Cases

    func testQualityAllCases() {
        let allCases = CaptureConfiguration.CaptureQuality.allCases
        XCTAssertEqual(allCases.count, 3)
        XCTAssertTrue(allCases.contains(.low))
        XCTAssertTrue(allCases.contains(.medium))
        XCTAssertTrue(allCases.contains(.high))
    }

    // MARK: - Custom Configuration

    func testCustomConfiguration() {
        var config = CaptureConfiguration()
        config.framesPerSecond = 60
        config.showsCursor = false
        config.quality = .low

        XCTAssertEqual(config.framesPerSecond, 60)
        XCTAssertFalse(config.showsCursor)
        XCTAssertEqual(config.quality, .low)
    }

    // MARK: - Codable

    func testEncodeDecode() throws {
        var config = CaptureConfiguration()
        config.framesPerSecond = 24
        config.showsCursor = false
        config.quality = .medium
        config.capturesMouseClicks = true

        let encoder = JSONEncoder()
        let data = try encoder.encode(config)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CaptureConfiguration.self, from: data)

        XCTAssertEqual(decoded.framesPerSecond, 24)
        XCTAssertFalse(decoded.showsCursor)
        XCTAssertEqual(decoded.quality, .medium)
        XCTAssertTrue(decoded.capturesMouseClicks)
    }

    // MARK: - Equatable

    func testEquality() {
        let config1 = CaptureConfiguration()
        let config2 = CaptureConfiguration()

        XCTAssertEqual(config1, config2)
    }

    func testInequality() {
        var config1 = CaptureConfiguration()
        var config2 = CaptureConfiguration()
        config2.framesPerSecond = 60

        XCTAssertNotEqual(config1, config2)
    }

    // MARK: - Frames Per Second Bounds

    func testFramesPerSecondBounds() {
        var config = CaptureConfiguration()

        // Test setting various FPS values
        config.framesPerSecond = 1
        XCTAssertEqual(config.framesPerSecond, 1)

        config.framesPerSecond = 120
        XCTAssertEqual(config.framesPerSecond, 120)
    }
}
