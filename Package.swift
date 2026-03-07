// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AnimaMac",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.12.0")
    ],
    targets: [
        .executableTarget(
            name: "AnimaMac",
            path: "AnimaMac",
            exclude: ["Info.plist", "AnimaMac.entitlements", "Resources"],
            sources: [
                "App/AnimaMacApp.swift",
                "App/AppState.swift",
                "Capture/ScreenRecorder.swift",
                "Capture/CaptureConfiguration.swift",
                "Capture/WindowPicker.swift",
                "Export/FFmpegManager.swift",
                "Export/GIFExporter.swift",
                "Export/ExportSettings.swift",
                "Storage/Recording.swift",
                "Storage/RecordingLibrary.swift",
                "Storage/FileManager+AnimaMac.swift",
                "UI/MenuBarView.swift",
                "UI/RecordingOverlay.swift",
                "UI/SettingsView.swift"
            ]
        ),
        .testTarget(
            name: "AnimaMacTests",
            dependencies: [
                "AnimaMac",
                .product(name: "Testing", package: "swift-testing")
            ],
            path: "AnimaMacTests"
        )
    ]
)
