import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView {
            RecordingSettingsTab()
                .environmentObject(appState)
                .tabItem {
                    Label("Recording", systemImage: "record.circle")
                }

            ExportSettingsTab()
                .environmentObject(appState)
                .tabItem {
                    Label("Export", systemImage: "square.and.arrow.up")
                }

            StorageSettingsTab()
                .environmentObject(appState)
                .tabItem {
                    Label("Storage", systemImage: "folder")
                }

            AboutTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 300)
    }
}

// MARK: - Recording Settings

struct RecordingSettingsTab: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Form {
            Picker("Quality", selection: $appState.captureConfiguration.quality) {
                ForEach(CaptureConfiguration.CaptureQuality.allCases, id: \.self) { quality in
                    Text(quality.displayName).tag(quality)
                }
            }

            Picker("Frame Rate", selection: $appState.captureConfiguration.framesPerSecond) {
                Text("15 fps").tag(15)
                Text("30 fps").tag(30)
                Text("60 fps").tag(60)
            }

            Toggle("Show cursor", isOn: $appState.captureConfiguration.showsCursor)

            Toggle("Include window shadow", isOn: $appState.captureConfiguration.includeWindowShadow)
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Export Settings

struct ExportSettingsTab: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Form {
            Section("Preset") {
                Picker("Quality Preset", selection: $appState.exportSettings.preset) {
                    ForEach(ExportPreset.allCases) { preset in
                        Text(preset.displayName).tag(preset)
                    }
                }
            }

            Section("Advanced") {
                LabeledContent("FPS") {
                    Text("\(appState.exportSettings.fps)")
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Max Width") {
                    Text("\(appState.exportSettings.maxWidth)px")
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Colors") {
                    Text("\(appState.exportSettings.maxColors)")
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Dithering") {
                    Text(appState.exportSettings.dithering.displayName)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Loop") {
                Picker("Loop Count", selection: $appState.exportSettings.loopCount) {
                    Text("Infinite").tag(0)
                    Text("Once").tag(1)
                    Text("Twice").tag(2)
                    Text("3 times").tag(3)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Storage Settings

struct StorageSettingsTab: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Form {
            Section("Storage Location") {
                LabeledContent("Recordings folder") {
                    Button("Open in Finder") {
                        NSWorkspace.shared.selectFile(
                            nil,
                            inFileViewerRootedAtPath: FileManager.animaMacRecordingsDirectory.path
                        )
                    }
                }

                LabeledContent("Storage used") {
                    Text(appState.recordingLibrary?.formattedStorageUsed ?? "0 MB")
                        .foregroundStyle(.secondary)
                }

                LabeledContent("Recordings") {
                    Text("\(appState.recordings.count)")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button("Delete All Recordings", role: .destructive) {
                    appState.recordingLibrary?.deleteAll()
                    appState.recordings.removeAll()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - About Tab

struct AboutTab: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "record.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.red)

            Text("AnimaMac")
                .font(.title)
                .fontWeight(.bold)

            Text("Version 1.0.0")
                .foregroundStyle(.secondary)

            Text("A simple GIF recorder for macOS")
                .foregroundStyle(.secondary)

            Spacer()

            Text("Built with SwiftUI and ScreenCaptureKit")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
