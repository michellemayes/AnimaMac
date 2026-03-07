import Foundation
import Testing
@testable import AnimaMacCore

@Suite("DurationFormatter")
struct DurationFormatterTests {

    @Test("Format zero") func zero() { #expect(DurationFormatter.format(0) == "00:00.0") }
    @Test("Format seconds") func seconds() { #expect(DurationFormatter.format(45) == "00:45.0") }
    @Test("Format minutes and seconds") func minutesSeconds() { #expect(DurationFormatter.format(125) == "02:05.0") }
    @Test("Format with tenths") func tenths() { #expect(DurationFormatter.format(45.7) == "00:45.7") }
    @Test("Format long duration") func longDuration() { #expect(DurationFormatter.format(3661.5) == "61:01.5") }

    @Test("Compact zero") func compactZero() { #expect(DurationFormatter.formatCompact(0) == "0s") }
    @Test("Compact seconds") func compactSeconds() { #expect(DurationFormatter.formatCompact(45) == "45s") }
    @Test("Compact minutes and seconds") func compactMinutes() { #expect(DurationFormatter.formatCompact(125) == "2m 5s") }
    @Test("Compact exact minute") func compactExactMinute() { #expect(DurationFormatter.formatCompact(60) == "1m 0s") }
    @Test("Compact fractional truncates") func compactFractional() { #expect(DurationFormatter.formatCompact(45.9) == "45s") }
}

@Suite("FileSizeFormatter")
struct FileSizeFormatterTests {

    @Test("Format bytes") func bytes() { #expect(!FileSizeFormatter.format(500).isEmpty) }
    @Test("Format KB") func kilobytes() { #expect(!FileSizeFormatter.format(1024).isEmpty) }
    @Test("Format MB") func megabytes() { #expect(!FileSizeFormatter.format(1024 * 1024).isEmpty) }
    @Test("Format GB") func gigabytes() { #expect(!FileSizeFormatter.format(Int64(1024 * 1024 * 1024)).isEmpty) }
    @Test("Format storage zero") func storageZero() { #expect(!FileSizeFormatter.formatStorage(0).isEmpty) }
}

@Suite("ExportProgressCalculator")
struct ExportProgressCalculatorTests {

    @Test("Percentage zero") func zero() { #expect(ExportProgressCalculator.percentage(0.0) == 0) }
    @Test("Percentage full") func full() { #expect(ExportProgressCalculator.percentage(1.0) == 100) }
    @Test("Percentage half") func half() { #expect(ExportProgressCalculator.percentage(0.5) == 50) }
    @Test("Clamps negative") func clampsNegative() { #expect(ExportProgressCalculator.percentage(-0.5) == 0) }
    @Test("Clamps over one") func clampsOver() { #expect(ExportProgressCalculator.percentage(1.5) == 100) }

    @Test("Format percentage zero") func formatZero() { #expect(ExportProgressCalculator.formatPercentage(0.0) == "0%") }
    @Test("Format percentage full") func formatFull() { #expect(ExportProgressCalculator.formatPercentage(1.0) == "100%") }
    @Test("Format percentage quarter") func formatQuarter() { #expect(ExportProgressCalculator.formatPercentage(0.25) == "25%") }
}

@Suite("ViewStateCalculator")
struct ViewStateCalculatorTests {

    @Test("Error state") func error() {
        #expect(ViewStateCalculator.determineMenuState(showingError: true, isRecording: false, isExporting: false) == .error)
    }
    @Test("Recording state") func recording() {
        #expect(ViewStateCalculator.determineMenuState(showingError: false, isRecording: true, isExporting: false) == .recording)
    }
    @Test("Exporting state") func exporting() {
        #expect(ViewStateCalculator.determineMenuState(showingError: false, isRecording: false, isExporting: true) == .exporting)
    }
    @Test("Main menu state") func mainMenu() {
        #expect(ViewStateCalculator.determineMenuState(showingError: false, isRecording: false, isExporting: false) == .mainMenu)
    }
    @Test("Error takes precedence") func errorPrecedence() {
        #expect(ViewStateCalculator.determineMenuState(showingError: true, isRecording: true, isExporting: false) == .error)
    }
    @Test("Recording takes precedence over exporting") func recordingPrecedence() {
        #expect(ViewStateCalculator.determineMenuState(showingError: false, isRecording: true, isExporting: true) == .recording)
    }
}

@Suite("SelectionCalculator")
struct SelectionCalculatorTests {

    @Test("Top-left to bottom-right") func topLeftToBottomRight() {
        let rect = SelectionCalculator.calculateRect(from: CGPoint(x: 10, y: 10), to: CGPoint(x: 100, y: 100))
        #expect(rect.origin.x == 10)
        #expect(rect.origin.y == 10)
        #expect(rect.width == 90)
        #expect(rect.height == 90)
    }

    @Test("Bottom-right to top-left") func bottomRightToTopLeft() {
        let rect = SelectionCalculator.calculateRect(from: CGPoint(x: 100, y: 100), to: CGPoint(x: 10, y: 10))
        #expect(rect.origin.x == 10)
        #expect(rect.origin.y == 10)
        #expect(rect.width == 90)
        #expect(rect.height == 90)
    }

    @Test("Convert to screen coordinates") func convertCoords() {
        let rect = SelectionCalculator.convertToScreenCoordinates(rect: CGRect(x: 50, y: 100, width: 200, height: 150), viewHeight: 800)
        #expect(rect.origin.x == 50)
        #expect(rect.origin.y == 550)
        #expect(rect.width == 200)
        #expect(rect.height == 150)
    }

    @Test("Valid selection") func validSelection() {
        #expect(SelectionCalculator.isValidSelection(CGRect(x: 0, y: 0, width: 100, height: 100)))
    }

    @Test("Too small selection") func tooSmall() {
        #expect(!SelectionCalculator.isValidSelection(CGRect(x: 0, y: 0, width: 5, height: 5)))
    }

    @Test("Custom minimum size") func customMinimum() {
        #expect(!SelectionCalculator.isValidSelection(CGRect(x: 0, y: 0, width: 30, height: 30), minimumSize: 50))
        #expect(SelectionCalculator.isValidSelection(CGRect(x: 0, y: 0, width: 30, height: 30), minimumSize: 20))
    }

    @Test("Aspect ratio") func aspectRatio() {
        #expect(SelectionCalculator.aspectRatio(of: CGRect(x: 0, y: 0, width: 200, height: 100)) == 2.0)
        #expect(SelectionCalculator.aspectRatio(of: CGRect(x: 0, y: 0, width: 100, height: 100)) == 1.0)
        #expect(SelectionCalculator.aspectRatio(of: CGRect(x: 0, y: 0, width: 100, height: 0)) == 0)
    }

    @Test("Area calculation") func area() {
        #expect(SelectionCalculator.area(of: CGRect(x: 0, y: 0, width: 100, height: 50)) == 5000)
        #expect(SelectionCalculator.area(of: CGRect(x: 0, y: 0, width: 0, height: 100)) == 0)
    }

    @Test("Constrain within bounds") func constrain() {
        let bounds = CGRect(x: 0, y: 0, width: 500, height: 500)
        let c1 = SelectionCalculator.constrain(CGRect(x: 50, y: 50, width: 100, height: 100), to: bounds)
        #expect(c1 == CGRect(x: 50, y: 50, width: 100, height: 100))

        let c2 = SelectionCalculator.constrain(CGRect(x: -20, y: 50, width: 100, height: 100), to: bounds)
        #expect(c2.origin.x == 0)

        let c3 = SelectionCalculator.constrain(CGRect(x: 450, y: 50, width: 100, height: 100), to: bounds)
        #expect(c3.size.width == 50)
    }
}

@Suite("KeyboardCodes")
struct KeyboardCodesTests {
    @Test("Key codes") func keyCodes() {
        #expect(KeyboardCodes.escape == 53)
        #expect(KeyboardCodes.space == 49)
        #expect(KeyboardCodes.returnKey == 36)
    }
}
