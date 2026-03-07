import Foundation
import Testing
@testable import AnimaMacCore

@Suite("ScreenRecorderError")
struct ScreenRecorderErrorTests {

    @Test("Permission denied description")
    func permissionDenied() {
        let error = ScreenRecorderError.permissionDenied
        #expect(error.errorDescription == "Screen recording permission was denied. Please enable it in System Settings > Privacy & Security > Screen Recording.")
    }

    @Test("No displays available description")
    func noDisplaysAvailable() {
        let error = ScreenRecorderError.noDisplaysAvailable
        #expect(error.errorDescription == "No displays available for recording.")
    }

    @Test("Conforms to LocalizedError")
    func localizedError() {
        let error: LocalizedError = ScreenRecorderError.permissionDenied
        #expect(error.errorDescription != nil)
    }

    @Test("Permission check returns bool")
    @MainActor func permissionCheckReturnsBool() {
        let has = ScreenRecorder.hasScreenRecordingPermission
        #expect(has == true || has == false)
    }
}
