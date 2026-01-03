import Foundation

struct ExportSettings: Codable, Equatable {
    var preset: ExportPreset = .medium
    var customFPS: Int?
    var customMaxWidth: Int?
    var customMaxColors: Int?
    var customDithering: DitheringMode?
    var loopCount: Int = 0  // 0 = infinite loop

    var fps: Int {
        customFPS ?? preset.fps
    }

    var maxWidth: Int {
        customMaxWidth ?? preset.maxWidth
    }

    var maxColors: Int {
        customMaxColors ?? preset.maxColors
    }

    var dithering: DitheringMode {
        customDithering ?? preset.dithering
    }
}

enum ExportPreset: String, Codable, CaseIterable, Identifiable {
    case small
    case medium
    case large
    case original

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .small: return "Small (Fast upload)"
        case .medium: return "Medium (Balanced)"
        case .large: return "Large (High quality)"
        case .original: return "Original (Maximum quality)"
        }
    }

    var fps: Int {
        switch self {
        case .small: return 10
        case .medium: return 15
        case .large: return 20
        case .original: return 30
        }
    }

    var maxWidth: Int {
        switch self {
        case .small: return 480
        case .medium: return 640
        case .large: return 1280
        case .original: return 9999  // No limit
        }
    }

    var maxColors: Int {
        switch self {
        case .small: return 128
        case .medium: return 256
        case .large: return 256
        case .original: return 256
        }
    }

    var dithering: DitheringMode {
        switch self {
        case .small: return .bayer
        case .medium: return .sierra2
        case .large: return .floydSteinberg
        case .original: return .floydSteinberg
        }
    }
}

enum DitheringMode: String, Codable, CaseIterable, Identifiable {
    case none
    case bayer
    case sierra2
    case sierra2_4a
    case floydSteinberg

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return "None (sharp edges)"
        case .bayer: return "Bayer (ordered)"
        case .sierra2: return "Sierra-2"
        case .sierra2_4a: return "Sierra-2-4A (fast)"
        case .floydSteinberg: return "Floyd-Steinberg (smooth)"
        }
    }

    var ffmpegValue: String {
        switch self {
        case .none: return "none"
        case .bayer: return "bayer"
        case .sierra2: return "sierra2"
        case .sierra2_4a: return "sierra2_4a"
        case .floydSteinberg: return "floyd_steinberg"
        }
    }
}
