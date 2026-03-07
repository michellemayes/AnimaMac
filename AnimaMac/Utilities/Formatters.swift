import Foundation

// MARK: - Duration Formatter

enum DurationFormatter {
    /// Formats a duration as "MM:SS.t" (e.g., "02:35.4")
    static func format(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let tenths = Int((duration * 10).truncatingRemainder(dividingBy: 10))
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }

    /// Formats a duration as "Xm Ys" or "Xs" (e.g., "2m 35s" or "45s")
    static func formatCompact(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
}

// MARK: - File Size Formatter

enum FileSizeFormatter {
    /// Formats bytes as human-readable size (e.g., "1.5 MB")
    static func format(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    /// Formats bytes as storage display (e.g., "1.5 MB")
    static func formatStorage(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Export Progress Calculator

enum ExportProgressCalculator {
    /// Calculates progress percentage as an integer (0-100)
    static func percentage(_ progress: Double) -> Int {
        Int(min(1.0, max(0.0, progress)) * 100)
    }

    /// Formats progress as a percentage string (e.g., "75%")
    static func formatPercentage(_ progress: Double) -> String {
        "\(percentage(progress))%"
    }
}

// MARK: - View State Calculator

enum ViewStateCalculator {
    enum MenuState {
        case error
        case recording
        case exporting
        case mainMenu
    }

    /// Determines which menu state to show based on app state
    static func determineMenuState(
        showingError: Bool,
        isRecording: Bool,
        isExporting: Bool
    ) -> MenuState {
        if showingError {
            return .error
        } else if isRecording {
            return .recording
        } else if isExporting {
            return .exporting
        } else {
            return .mainMenu
        }
    }
}

// MARK: - Selection Calculator

enum SelectionCalculator {
    /// Calculate a rectangle from two points (handles any drag direction)
    static func calculateRect(from startPoint: CGPoint, to endPoint: CGPoint) -> CGRect {
        CGRect(
            x: min(startPoint.x, endPoint.x),
            y: min(startPoint.y, endPoint.y),
            width: abs(endPoint.x - startPoint.x),
            height: abs(endPoint.y - startPoint.y)
        )
    }

    /// Convert a view-space rect to screen-space (flips Y axis)
    static func convertToScreenCoordinates(rect: CGRect, viewHeight: CGFloat) -> CGRect {
        CGRect(
            x: rect.origin.x,
            y: viewHeight - rect.origin.y - rect.height,
            width: rect.width,
            height: rect.height
        )
    }

    /// Check if a selection rectangle is large enough to be valid
    static func isValidSelection(_ rect: CGRect, minimumSize: CGFloat = 10) -> Bool {
        rect.width > minimumSize && rect.height > minimumSize
    }

    /// Calculate aspect ratio of a rectangle
    static func aspectRatio(of rect: CGRect) -> Double {
        guard rect.height > 0 else { return 0 }
        return Double(rect.width / rect.height)
    }

    /// Calculate area of a rectangle in pixels
    static func area(of rect: CGRect) -> Double {
        Double(rect.width * rect.height)
    }

    /// Constrain a rectangle to fit within bounds
    static func constrain(_ rect: CGRect, to bounds: CGRect) -> CGRect {
        var constrained = rect

        // Constrain to bounds
        if constrained.minX < bounds.minX {
            constrained.origin.x = bounds.minX
        }
        if constrained.minY < bounds.minY {
            constrained.origin.y = bounds.minY
        }
        if constrained.maxX > bounds.maxX {
            constrained.size.width = bounds.maxX - constrained.origin.x
        }
        if constrained.maxY > bounds.maxY {
            constrained.size.height = bounds.maxY - constrained.origin.y
        }

        return constrained
    }
}

// MARK: - Keyboard Code Constants

enum KeyboardCodes {
    static let escape: UInt16 = 53
    static let space: UInt16 = 49
    static let returnKey: UInt16 = 36
}
