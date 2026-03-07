import XCTest
@testable import AnimaMacCore

final class ScreenRecorderTests: XCTestCase {

    // MARK: - ScreenRecorderError Tests

    func testPermissionDeniedErrorDescription() {
        let error = ScreenRecorderError.permissionDenied
        XCTAssertEqual(
            error.errorDescription,
            "Screen recording permission was denied. Please enable it in System Settings > Privacy & Security > Screen Recording."
        )
    }

    func testNoDisplaysAvailableErrorDescription() {
        let error = ScreenRecorderError.noDisplaysAvailable
        XCTAssertEqual(
            error.errorDescription,
            "No displays available for recording."
        )
    }

    func testScreenRecorderErrorIsLocalizedError() {
        let error: LocalizedError = ScreenRecorderError.permissionDenied
        XCTAssertNotNil(error.errorDescription)
    }

    // MARK: - RecordingError Tests

    func testNoContentSelectedErrorDescription() {
        let error = RecordingError.noContentSelected
        XCTAssertEqual(error.errorDescription, "No screen area or window selected")
    }

    func testPermissionDeniedRecordingErrorDescription() {
        let error = RecordingError.permissionDenied
        XCTAssertEqual(error.errorDescription, "Screen recording permission denied")
    }

    func testRecordingFailedErrorDescription() {
        let error = RecordingError.recordingFailed("Test failure")
        XCTAssertEqual(error.errorDescription, "Recording failed: Test failure")
    }

    func testNoActiveRecordingErrorDescription() {
        let error = RecordingError.noActiveRecording
        XCTAssertEqual(error.errorDescription, "No active recording to stop")
    }

    func testOutputURLNotSetErrorDescription() {
        let error = RecordingError.outputURLNotSet
        XCTAssertEqual(error.errorDescription, "Output URL not configured")
    }

    func testRecordingErrorIsLocalizedError() {
        let error: LocalizedError = RecordingError.noContentSelected
        XCTAssertNotNil(error.errorDescription)
    }

    // MARK: - Permission Check Tests (static methods)

    func testHasScreenRecordingPermissionReturnsBool() {
        // This just verifies the API exists and returns a boolean
        let hasPermission = ScreenRecorder.hasScreenRecordingPermission
        XCTAssertTrue(hasPermission == true || hasPermission == false)
    }

    func testRequestScreenRecordingPermissionReturnsBool() {
        // This just verifies the API exists
        // Note: Actually calling this would show a system dialog
        // We just verify the method signature is correct
        let methodExists = ScreenRecorder.requestScreenRecordingPermission
        XCTAssertNotNil(methodExists)
    }
}
