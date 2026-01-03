import SwiftUI

@main
struct AnimaMacApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appState)
        } label: {
            Image(systemName: appState.isRecording ? "record.circle.fill" : "record.circle")
                .symbolRenderingMode(.palette)
                .foregroundStyle(appState.isRecording ? .red : .primary, .primary)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
