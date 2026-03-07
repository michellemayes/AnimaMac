import Foundation
import Testing
@testable import AnimaMac

@Suite("FFmpegManager")
struct FFmpegManagerTests {

    @Test("shared is singleton")
    func sharedSingleton() async {
        let a = FFmpegManager.shared
        let b = FFmpegManager.shared
        #expect(a === b)
    }

    @Test("isAvailable checks file existence")
    func isAvailableChecksFile() async {
        let available = await FFmpegManager.shared.isAvailable
        let fileExists = FileManager.default.fileExists(atPath: FileManager.ffmpegBinaryURL.path)
        #expect(available == fileExists)
    }
}
