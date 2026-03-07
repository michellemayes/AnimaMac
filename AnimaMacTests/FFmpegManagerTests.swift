import Foundation
import Testing
@testable import AnimaMacCore

@Suite("FFmpegManager")
struct FFmpegManagerTests {

    @Test("shared is singleton")
    func sharedSingleton() async {
        let a = FFmpegManager.shared
        let b = FFmpegManager.shared
        #expect(a === b)
    }

    @Test("isAvailable is consistent across calls")
    func isAvailableConsistent() async {
        let first = await FFmpegManager.shared.isAvailable
        let second = await FFmpegManager.shared.isAvailable
        #expect(first == second)
    }

    @Test("executableURL contains ffmpeg")
    func executableURLContainsFFmpeg() async {
        let url = await FFmpegManager.shared.executableURL
        #expect(url.isFileURL)
        #expect(url.path.contains("ffmpeg"))
    }
}
