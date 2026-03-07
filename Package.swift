// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AnimaMac",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "AnimaMacCore", targets: ["AnimaMacCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.12.0")
    ],
    targets: [
        // Core library with all the business logic (testable)
        .target(
            name: "AnimaMacCore",
            path: "AnimaMac",
            exclude: ["Info.plist", "AnimaMac.entitlements", "Resources", "App/AnimaMacApp.swift"],
            sources: [
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
                "UI/SettingsView.swift",
                "Utilities/Formatters.swift"
            ]
        ),
        // Test target
        .testTarget(
            name: "AnimaMacTests",
            dependencies: [
                "AnimaMacCore",
                .product(name: "Testing", package: "swift-testing")
            ],
            path: "AnimaMacTests"
        )
    ]
)
