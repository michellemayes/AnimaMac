import SwiftUI
import ScreenCaptureKit

struct WindowPickerView: View {
    @EnvironmentObject var appState: AppState
    @State private var windows: [SCWindow] = []
    @State private var displays: [SCDisplay] = []
    @State private var selectedTab = 0
    @State private var isLoading = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Select what to record")
                    .font(.headline)
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            // Tab picker
            Picker("", selection: $selectedTab) {
                Text("Windows").tag(0)
                Text("Displays").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TabView(selection: $selectedTab) {
                    windowsList.tag(0)
                    displaysList.tag(1)
                }
                .tabViewStyle(.automatic)
            }
        }
        .frame(width: 400, height: 500)
        .task {
            await loadContent()
        }
    }

    // MARK: - Windows List

    private var windowsList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(windows, id: \.windowID) { window in
                    WindowRow(window: window) {
                        selectWindow(window)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Displays List

    private var displaysList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(displays, id: \.displayID) { display in
                    DisplayRow(display: display) {
                        selectDisplay(display)
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Actions

    private func loadContent() async {
        isLoading = true
        defer { isLoading = false }

        do {
            windows = try await ScreenRecorder.availableWindows()
            displays = try await ScreenRecorder.availableDisplays()
        } catch {
            print("Failed to load content: \(error)")
        }
    }

    private func selectWindow(_ window: SCWindow) {
        appState.selectedWindow = window
        appState.isSelectingWindow = false
        dismiss()

        Task {
            try? await appState.startRecording()
        }
    }

    private func selectDisplay(_ display: SCDisplay) {
        appState.selectedDisplay = display
        appState.isSelectingWindow = false
        dismiss()

        // Start area selection on this display
        appState.startAreaSelection()
    }
}

// MARK: - Window Row

struct WindowRow: View {
    let window: SCWindow
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // App icon
                if let app = window.owningApplication,
                   let bundleID = app.bundleIdentifier,
                   let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                    AsyncImage(url: appURL) { image in
                        image.resizable()
                    } placeholder: {
                        Image(systemName: "app.fill")
                    }
                    .frame(width: 32, height: 32)
                } else {
                    Image(systemName: "macwindow")
                        .font(.title)
                        .frame(width: 32, height: 32)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(window.title ?? "Untitled Window")
                        .font(.body)
                        .lineLimit(1)

                    if let app = window.owningApplication {
                        Text(app.applicationName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let frame = window.frame {
                    Text("\(Int(frame.width)) x \(Int(frame.height))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isHovering ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

// MARK: - Display Row

struct DisplayRow: View {
    let display: SCDisplay
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "display")
                    .font(.title)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Display \(display.displayID)")
                        .font(.body)

                    Text("\(display.width) x \(display.height)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text("Full Screen")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isHovering ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

#Preview {
    WindowPickerView()
        .environmentObject(AppState())
}
