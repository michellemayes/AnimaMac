import Foundation
import Testing

@testable import AnimaMac

@Suite("RecordingError")
struct RecordingErrorTests {

    @Test("noContentSelected description")
    func noContentSelected() {
        #expect(RecordingError.noContentSelected.errorDescription == "No screen area or window selected")
    }

    @Test("permissionDenied description")
    func permissionDenied() {
        #expect(RecordingError.permissionDenied.errorDescription == "Screen recording permission denied")
    }

    @Test("recordingFailed includes reason")
    func recordingFailed() {
        #expect(RecordingError.recordingFailed("timeout").errorDescription == "Recording failed: timeout")
    }

    @Test("noActiveRecording description")
    func noActiveRecording() {
        #expect(RecordingError.noActiveRecording.errorDescription == "No active recording to stop")
    }

    @Test("outputURLNotSet description")
    func outputURLNotSet() {
        #expect(RecordingError.outputURLNotSet.errorDescription == "Output URL not configured")
    }
}

@Suite("FFmpegError")
struct FFmpegErrorTests {

    @Test("downloadFailed description")
    func downloadFailed() {
        #expect(FFmpegError.downloadFailed.errorDescription == "Failed to download FFmpeg")
    }

    @Test("extractionFailed description")
    func extractionFailed() {
        #expect(FFmpegError.extractionFailed.errorDescription == "Failed to extract FFmpeg")
    }

    @Test("binaryNotFound description")
    func binaryNotFound() {
        #expect(FFmpegError.binaryNotFound.errorDescription == "FFmpeg binary not found in download")
    }

    @Test("executionFailed includes message")
    func executionFailed() {
        #expect(FFmpegError.executionFailed("codec not found").errorDescription == "FFmpeg error: codec not found")
    }
}
