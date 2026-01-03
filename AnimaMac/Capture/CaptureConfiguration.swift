import Foundation
import ScreenCaptureKit

struct CaptureConfiguration: Codable, Equatable {
    var framesPerSecond: Int = 30
    var showsCursor: Bool = true
    var capturesMouseClicks: Bool = false
    var capturesKeyboardInput: Bool = false
    var includeWindowShadow: Bool = true
    var quality: CaptureQuality = .high

    enum CaptureQuality: String, Codable, CaseIterable {
        case low
        case medium
        case high

        var displayName: String {
            switch self {
            case .low: return "Low (smaller file)"
            case .medium: return "Medium"
            case .high: return "High (best quality)"
            }
        }

        var scaleFactor: CGFloat {
            switch self {
            case .low: return 0.5
            case .medium: return 0.75
            case .high: return 1.0
            }
        }
    }

    func applyTo(_ configuration: SCStreamConfiguration, for display: SCDisplay) {
        let scaleFactor = quality.scaleFactor
        configuration.width = Int(CGFloat(display.width) * scaleFactor)
        configuration.height = Int(CGFloat(display.height) * scaleFactor)
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(framesPerSecond))
        configuration.showsCursor = showsCursor
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        configuration.queueDepth = 5
    }

    func applyTo(_ configuration: SCStreamConfiguration, for window: SCWindow) {
        let scaleFactor = quality.scaleFactor
        let frame = window.frame
        
        // Check for valid frame dimensions
        guard frame.width > 0 && frame.height > 0 else {
            // Default dimensions if frame dimensions are invalid
            configuration.width = 1920
            configuration.height = 1080
            configuration.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(framesPerSecond))
            configuration.showsCursor = showsCursor
            configuration.pixelFormat = kCVPixelFormatType_32BGRA
            configuration.queueDepth = 5
            return
        }
        
        configuration.width = Int(frame.width * scaleFactor)
        configuration.height = Int(frame.height * scaleFactor)
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(framesPerSecond))
        configuration.showsCursor = showsCursor
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        configuration.queueDepth = 5
    }
}
