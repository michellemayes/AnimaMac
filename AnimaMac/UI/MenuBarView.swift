import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            if appState.isRecording {
                recordingView
            } else if appState.isExporting {
                exportingView
            } else {
                mainMenuView
            }
        }
        .frame(width: 280)
    }

    // MARK: - Recording View

    private var recordingView: some View {
        VStack(spacing: 16) {
            HStack {
                Circle()
                    .fill(.red)
                    .frame(width: 12, height: 12)
                    .modifier(PulsingModifier())

                Text("Recording")
                    .font(.headline)

                Spacer()

                Text(formattedDuration)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            Button(action: stopRecording) {
                Label("Stop Recording", systemImage: "stop.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .keyboardShortcut(.escape, modifiers: .command)
        }
        .padding()
    }

    // MARK: - Exporting View

    private var exportingView: some View {
        VStack(spacing: 12) {
            Text("Creating GIF...")
                .font(.headline)

            ProgressView(value: appState.exportProgress)
                .progressViewStyle(.linear)

            Text("\(Int(appState.exportProgress * 100))%")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    // MARK: - Main Menu View

    private var mainMenuView: some View {
        VStack(spacing: 0) {
            // Record buttons
            VStack(spacing: 8) {
                Button(action: { appState.startAreaSelection() }) {
                    Label("Record Area", systemImage: "rectangle.dashed")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(8)

                Button(action: { appState.startWindowSelection() }) {
                    Label("Record Window", systemImage: "macwindow")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(8)
            }
            .padding()

            Divider()

            // Recent recordings
            if !appState.recordings.isEmpty {
                recentRecordingsSection
                Divider()
            }

            // Footer
            HStack {
                Button(action: openSettings) {
                    Image(systemName: "gear")
                }
                .buttonStyle(.plain)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            .padding()
        }
    }

    // MARK: - Recent Recordings

    private var recentRecordingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
                .padding(.top, 8)

            ForEach(appState.recordings.prefix(5)) { recording in
                RecordingRow(recording: recording)
                    .environmentObject(appState)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Actions

    private func stopRecording() {
        Task {
            try? await appState.stopRecording()
        }
    }

    private func openSettings() {
        if #available(macOS 14.0, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }

    // MARK: - Helpers

    private var formattedDuration: String {
        let minutes = Int(appState.recordingDuration) / 60
        let seconds = Int(appState.recordingDuration) % 60
        let tenths = Int((appState.recordingDuration * 10).truncatingRemainder(dividingBy: 10))
        return String(format: "%02d:%02d.%d", minutes, seconds, tenths)
    }
}

// MARK: - Recording Row

struct RecordingRow: View {
    let recording: Recording
    @EnvironmentObject var appState: AppState
    @State private var isHovering = false

    var body: some View {
        HStack {
            // Thumbnail placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.secondary.opacity(0.2))
                .frame(width: 48, height: 36)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(recording.createdAt, style: .time)
                    .font(.caption)

                Text(recording.formattedDuration)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isHovering {
                HStack(spacing: 8) {
                    Button(action: { appState.revealInFinder(recording) }) {
                        Image(systemName: "folder")
                    }
                    .buttonStyle(.plain)

                    Button(action: { appState.deleteRecording(recording) }) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.red)
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(isHovering ? Color.secondary.opacity(0.1) : Color.clear)
        .cornerRadius(6)
        .onHover { isHovering = $0 }
    }
}

// MARK: - Pulsing Modifier

struct PulsingModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .opacity(isPulsing ? 0.4 : 1.0)
            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isPulsing)
            .onAppear { isPulsing = true }
    }
}

