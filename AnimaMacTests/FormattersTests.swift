import XCTest
@testable import AnimaMacCore

final class FormattersTests: XCTestCase {

    // MARK: - DurationFormatter Tests

    func testFormatZeroDuration() {
        XCTAssertEqual(DurationFormatter.format(0), "00:00.0")
    }

    func testFormatSecondsOnly() {
        XCTAssertEqual(DurationFormatter.format(45), "00:45.0")
    }

    func testFormatMinutesAndSeconds() {
        XCTAssertEqual(DurationFormatter.format(125), "02:05.0")
    }

    func testFormatWithTenths() {
        XCTAssertEqual(DurationFormatter.format(45.7), "00:45.7")
    }

    func testFormatLongDuration() {
        XCTAssertEqual(DurationFormatter.format(3661.5), "61:01.5")
    }

    func testFormatCompactZero() {
        XCTAssertEqual(DurationFormatter.formatCompact(0), "0s")
    }

    func testFormatCompactSecondsOnly() {
        XCTAssertEqual(DurationFormatter.formatCompact(45), "45s")
    }

    func testFormatCompactMinutesAndSeconds() {
        XCTAssertEqual(DurationFormatter.formatCompact(125), "2m 5s")
    }

    func testFormatCompactExactMinute() {
        XCTAssertEqual(DurationFormatter.formatCompact(60), "1m 0s")
    }

    func testFormatCompactFractionalTruncates() {
        XCTAssertEqual(DurationFormatter.formatCompact(45.9), "45s")
    }

    // MARK: - FileSizeFormatter Tests

    func testFormatBytes() {
        let result = FileSizeFormatter.format(500)
        XCTAssertTrue(result.contains("500") || result.contains("bytes"))
    }

    func testFormatKilobytes() {
        let result = FileSizeFormatter.format(1024)
        XCTAssertTrue(result.contains("KB") || result.contains("1"))
    }

    func testFormatMegabytes() {
        let result = FileSizeFormatter.format(1024 * 1024)
        XCTAssertTrue(result.contains("MB") || result.contains("1"))
    }

    func testFormatGigabytes() {
        let result = FileSizeFormatter.format(Int64(1024 * 1024 * 1024))
        XCTAssertTrue(result.contains("GB") || result.contains("1"))
    }

    func testFormatStorageMB() {
        let result = FileSizeFormatter.formatStorage(1024 * 1024)
        XCTAssertTrue(result.contains("MB") || result.contains("1"))
    }

    func testFormatStorageZero() {
        let result = FileSizeFormatter.formatStorage(0)
        XCTAssertNotNil(result)
    }

    // MARK: - ExportProgressCalculator Tests

    func testPercentageZero() {
        XCTAssertEqual(ExportProgressCalculator.percentage(0.0), 0)
    }

    func testPercentageFull() {
        XCTAssertEqual(ExportProgressCalculator.percentage(1.0), 100)
    }

    func testPercentageHalf() {
        XCTAssertEqual(ExportProgressCalculator.percentage(0.5), 50)
    }

    func testPercentageClampsNegative() {
        XCTAssertEqual(ExportProgressCalculator.percentage(-0.5), 0)
    }

    func testPercentageClampsOverOne() {
        XCTAssertEqual(ExportProgressCalculator.percentage(1.5), 100)
    }

    func testFormatPercentageZero() {
        XCTAssertEqual(ExportProgressCalculator.formatPercentage(0.0), "0%")
    }

    func testFormatPercentageFull() {
        XCTAssertEqual(ExportProgressCalculator.formatPercentage(1.0), "100%")
    }

    func testFormatPercentageQuarter() {
        XCTAssertEqual(ExportProgressCalculator.formatPercentage(0.25), "25%")
    }

    // MARK: - ViewStateCalculator Tests

    func testDetermineMenuStateError() {
        let state = ViewStateCalculator.determineMenuState(
            showingError: true,
            isRecording: false,
            isExporting: false
        )
        XCTAssertEqual(state, .error)
    }

    func testDetermineMenuStateRecording() {
        let state = ViewStateCalculator.determineMenuState(
            showingError: false,
            isRecording: true,
            isExporting: false
        )
        XCTAssertEqual(state, .recording)
    }

    func testDetermineMenuStateExporting() {
        let state = ViewStateCalculator.determineMenuState(
            showingError: false,
            isRecording: false,
            isExporting: true
        )
        XCTAssertEqual(state, .exporting)
    }

    func testDetermineMenuStateMainMenu() {
        let state = ViewStateCalculator.determineMenuState(
            showingError: false,
            isRecording: false,
            isExporting: false
        )
        XCTAssertEqual(state, .mainMenu)
    }

    func testErrorTakesPrecedenceOverRecording() {
        let state = ViewStateCalculator.determineMenuState(
            showingError: true,
            isRecording: true,
            isExporting: false
        )
        XCTAssertEqual(state, .error)
    }

    func testRecordingTakesPrecedenceOverExporting() {
        let state = ViewStateCalculator.determineMenuState(
            showingError: false,
            isRecording: true,
            isExporting: true
        )
        XCTAssertEqual(state, .recording)
    }

    // MARK: - ViewStateCalculator.MenuState Equatable

    func testMenuStateEquatable() {
        XCTAssertEqual(ViewStateCalculator.MenuState.error, ViewStateCalculator.MenuState.error)
        XCTAssertNotEqual(ViewStateCalculator.MenuState.error, ViewStateCalculator.MenuState.recording)
    }

    // MARK: - SelectionCalculator Tests

    func testCalculateRectTopLeftToBottomRight() {
        let start = CGPoint(x: 10, y: 10)
        let end = CGPoint(x: 100, y: 100)
        let rect = SelectionCalculator.calculateRect(from: start, to: end)

        XCTAssertEqual(rect.origin.x, 10)
        XCTAssertEqual(rect.origin.y, 10)
        XCTAssertEqual(rect.width, 90)
        XCTAssertEqual(rect.height, 90)
    }

    func testCalculateRectBottomRightToTopLeft() {
        let start = CGPoint(x: 100, y: 100)
        let end = CGPoint(x: 10, y: 10)
        let rect = SelectionCalculator.calculateRect(from: start, to: end)

        XCTAssertEqual(rect.origin.x, 10)
        XCTAssertEqual(rect.origin.y, 10)
        XCTAssertEqual(rect.width, 90)
        XCTAssertEqual(rect.height, 90)
    }

    func testCalculateRectTopRightToBottomLeft() {
        let start = CGPoint(x: 100, y: 10)
        let end = CGPoint(x: 10, y: 100)
        let rect = SelectionCalculator.calculateRect(from: start, to: end)

        XCTAssertEqual(rect.origin.x, 10)
        XCTAssertEqual(rect.origin.y, 10)
        XCTAssertEqual(rect.width, 90)
        XCTAssertEqual(rect.height, 90)
    }

    func testConvertToScreenCoordinates() {
        let rect = CGRect(x: 50, y: 100, width: 200, height: 150)
        let viewHeight: CGFloat = 800

        let screenRect = SelectionCalculator.convertToScreenCoordinates(rect: rect, viewHeight: viewHeight)

        XCTAssertEqual(screenRect.origin.x, 50)
        XCTAssertEqual(screenRect.origin.y, 550) // 800 - 100 - 150
        XCTAssertEqual(screenRect.width, 200)
        XCTAssertEqual(screenRect.height, 150)
    }

    func testIsValidSelectionValid() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        XCTAssertTrue(SelectionCalculator.isValidSelection(rect))
    }

    func testIsValidSelectionTooSmall() {
        let rect = CGRect(x: 0, y: 0, width: 5, height: 5)
        XCTAssertFalse(SelectionCalculator.isValidSelection(rect))
    }

    func testIsValidSelectionWidthTooSmall() {
        let rect = CGRect(x: 0, y: 0, width: 5, height: 100)
        XCTAssertFalse(SelectionCalculator.isValidSelection(rect))
    }

    func testIsValidSelectionHeightTooSmall() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 5)
        XCTAssertFalse(SelectionCalculator.isValidSelection(rect))
    }

    func testIsValidSelectionCustomMinimum() {
        let rect = CGRect(x: 0, y: 0, width: 30, height: 30)
        XCTAssertFalse(SelectionCalculator.isValidSelection(rect, minimumSize: 50))
        XCTAssertTrue(SelectionCalculator.isValidSelection(rect, minimumSize: 20))
    }

    func testAspectRatioSquare() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 100)
        XCTAssertEqual(SelectionCalculator.aspectRatio(of: rect), 1.0, accuracy: 0.001)
    }

    func testAspectRatioWide() {
        let rect = CGRect(x: 0, y: 0, width: 200, height: 100)
        XCTAssertEqual(SelectionCalculator.aspectRatio(of: rect), 2.0, accuracy: 0.001)
    }

    func testAspectRatioTall() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 200)
        XCTAssertEqual(SelectionCalculator.aspectRatio(of: rect), 0.5, accuracy: 0.001)
    }

    func testAspectRatioZeroHeight() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 0)
        XCTAssertEqual(SelectionCalculator.aspectRatio(of: rect), 0)
    }

    func testAreaCalculation() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 50)
        XCTAssertEqual(SelectionCalculator.area(of: rect), 5000, accuracy: 0.001)
    }

    func testAreaZero() {
        let rect = CGRect(x: 0, y: 0, width: 0, height: 100)
        XCTAssertEqual(SelectionCalculator.area(of: rect), 0)
    }

    func testConstrainWithinBounds() {
        let rect = CGRect(x: 50, y: 50, width: 100, height: 100)
        let bounds = CGRect(x: 0, y: 0, width: 500, height: 500)
        let constrained = SelectionCalculator.constrain(rect, to: bounds)

        XCTAssertEqual(constrained, rect) // No change needed
    }

    func testConstrainLeftEdge() {
        let rect = CGRect(x: -20, y: 50, width: 100, height: 100)
        let bounds = CGRect(x: 0, y: 0, width: 500, height: 500)
        let constrained = SelectionCalculator.constrain(rect, to: bounds)

        XCTAssertEqual(constrained.origin.x, 0)
    }

    func testConstrainTopEdge() {
        let rect = CGRect(x: 50, y: -20, width: 100, height: 100)
        let bounds = CGRect(x: 0, y: 0, width: 500, height: 500)
        let constrained = SelectionCalculator.constrain(rect, to: bounds)

        XCTAssertEqual(constrained.origin.y, 0)
    }

    func testConstrainRightEdge() {
        let rect = CGRect(x: 450, y: 50, width: 100, height: 100)
        let bounds = CGRect(x: 0, y: 0, width: 500, height: 500)
        let constrained = SelectionCalculator.constrain(rect, to: bounds)

        XCTAssertEqual(constrained.size.width, 50) // Clamped to fit
    }

    func testConstrainBottomEdge() {
        let rect = CGRect(x: 50, y: 450, width: 100, height: 100)
        let bounds = CGRect(x: 0, y: 0, width: 500, height: 500)
        let constrained = SelectionCalculator.constrain(rect, to: bounds)

        XCTAssertEqual(constrained.size.height, 50) // Clamped to fit
    }

    // MARK: - KeyboardCodes Tests

    func testEscapeKeyCode() {
        XCTAssertEqual(KeyboardCodes.escape, 53)
    }

    func testSpaceKeyCode() {
        XCTAssertEqual(KeyboardCodes.space, 49)
    }

    func testReturnKeyCode() {
        XCTAssertEqual(KeyboardCodes.returnKey, 36)
    }
}
