import SwiftUI
import ScreenCaptureKit

struct RecordingOverlayWindow: NSViewRepresentable {
    @Binding var selectedRect: CGRect?
    @Binding var isSelecting: Bool
    let display: SCDisplay?
    let onComplete: (CGRect) -> Void
    let onCancel: () -> Void

    func makeNSView(context: Context) -> RecordingOverlayNSView {
        let view = RecordingOverlayNSView()
        view.onComplete = onComplete
        view.onCancel = onCancel
        return view
    }

    func updateNSView(_ nsView: RecordingOverlayNSView, context: Context) {
        nsView.onComplete = onComplete
        nsView.onCancel = onCancel
    }
}

class RecordingOverlayNSView: NSView {
    var onComplete: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?

    private var startPoint: NSPoint?
    private var currentRect: NSRect?
    private var isDragging = false

    private let selectionLayer = CAShapeLayer()
    private let dimLayer = CALayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }

    private func setupLayers() {
        wantsLayer = true

        // Dim layer covers entire screen
        dimLayer.backgroundColor = NSColor.black.withAlphaComponent(0.3).cgColor
        layer?.addSublayer(dimLayer)

        // Selection layer shows the selection rectangle
        selectionLayer.fillColor = NSColor.clear.cgColor
        selectionLayer.strokeColor = NSColor.white.cgColor
        selectionLayer.lineWidth = 2
        selectionLayer.lineDashPattern = [5, 5]
        layer?.addSublayer(selectionLayer)
    }

    override func layout() {
        super.layout()
        dimLayer.frame = bounds
    }

    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        isDragging = true
        currentRect = nil
        updateSelection()
    }

    override func mouseDragged(with event: NSEvent) {
        guard let start = startPoint else { return }
        let current = convert(event.locationInWindow, from: nil)

        let rect = NSRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: abs(current.x - start.x),
            height: abs(current.y - start.y)
        )

        currentRect = rect
        updateSelection()
    }

    override func mouseUp(with event: NSEvent) {
        isDragging = false

        if let rect = currentRect, rect.width > 10, rect.height > 10 {
            // Convert to screen coordinates (flip Y for macOS coordinate system)
            let screenRect = CGRect(
                x: rect.origin.x,
                y: bounds.height - rect.origin.y - rect.height,
                width: rect.width,
                height: rect.height
            )
            onComplete?(screenRect)
        }

        startPoint = nil
        currentRect = nil
        updateSelection()
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            onCancel?()
        } else if event.keyCode == 49 { // Space - start recording immediately with current selection
            if let rect = currentRect, rect.width > 10, rect.height > 10 {
                let screenRect = CGRect(
                    x: rect.origin.x,
                    y: bounds.height - rect.origin.y - rect.height,
                    width: rect.width,
                    height: rect.height
                )
                onComplete?(screenRect)
            }
        }
    }

    private func updateSelection() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        if let rect = currentRect {
            let path = CGPath(rect: rect, transform: nil)
            selectionLayer.path = path

            // Create hole in dim layer
            let fullPath = CGMutablePath()
            fullPath.addRect(bounds)
            fullPath.addRect(rect)

            let maskLayer = CAShapeLayer()
            maskLayer.path = fullPath
            maskLayer.fillRule = .evenOdd
            dimLayer.mask = maskLayer
        } else {
            selectionLayer.path = nil
            dimLayer.mask = nil
        }

        CATransaction.commit()
    }
}

// MARK: - Overlay Window Controller

@MainActor
class OverlayWindowController {
    private var overlayWindows: [NSWindow] = []

    func showOverlay(
        for display: SCDisplay,
        onComplete: @escaping (CGRect, SCDisplay) -> Void,
        onCancel: @escaping () -> Void
    ) {
        // Create fullscreen overlay window
        let frame = CGRect(
            x: CGFloat(display.frame.origin.x),
            y: CGFloat(display.frame.origin.y),
            width: CGFloat(display.width),
            height: CGFloat(display.height)
        )

        let window = NSWindow(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )

        window.level = .screenSaver
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let overlayView = RecordingOverlayNSView(frame: frame)
        overlayView.onComplete = { [weak self] rect in
            self?.hideOverlay()
            onComplete(rect, display)
        }
        overlayView.onCancel = { [weak self] in
            self?.hideOverlay()
            onCancel()
        }

        window.contentView = overlayView
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(overlayView)

        overlayWindows.append(window)
    }

    func hideOverlay() {
        for window in overlayWindows {
            window.orderOut(nil)
        }
        overlayWindows.removeAll()
    }
}

// MARK: - SwiftUI Overlay View

struct SelectionOverlayView: View {
    @EnvironmentObject var appState: AppState
    @State private var overlayController = OverlayWindowController()

    var body: some View {
        Color.clear
            .onChange(of: appState.isSelectingArea) { _, isSelecting in
                if isSelecting {
                    Task {
                        await showOverlay()
                    }
                } else {
                    overlayController.hideOverlay()
                }
            }
    }

    private func showOverlay() async {
        var display = appState.selectedDisplay
        if display == nil {
            display = try? await ScreenRecorder.availableDisplays().first
        }
        guard let display else {
            return
        }

        appState.selectedDisplay = display

        overlayController.showOverlay(
            for: display,
            onComplete: { rect, display in
                appState.selectedRect = rect
                appState.selectedDisplay = display
                appState.isSelectingArea = false

                Task {
                    try? await appState.startRecording()
                }
            },
            onCancel: {
                appState.cancelSelection()
            }
        )
    }
}
