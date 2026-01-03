---
name: AnimaMac Build & Test
description: Build, test, and verify AnimaMac macOS app. Use when building the project, fixing build errors, or verifying changes work correctly.
---

# AnimaMac Build & Test

## Build Commands

### Quick Build (SPM)
```bash
swift build
```
This builds the app using Swift Package Manager. Use for quick iteration.

### Full Build (Xcode)
```bash
xcodebuild -project AnimaMac.xcodeproj -scheme AnimaMac -configuration Debug build
```

### Run the App
After building with SPM, the binary is at:
```bash
.build/debug/AnimaMac
```

## Pre-Build Checklist

Before building, verify:

1. **No #Preview macros** - Swift Package Manager doesn't support `#Preview`. Remove or wrap in `#if DEBUG` with Xcode-only compilation.

2. **Swift 6 compatibility** - Some ScreenCaptureKit properties are non-optional in Swift 6:
   - `SCWindow.frame` is `CGRect` not `CGRect?`
   - `NSRunningApplication.bundleIdentifier` is `String` not `String?`
   - Don't use `if let` for these properties

3. **MainActor isolation** - Be careful with `@MainActor` on classes that implement `SCStreamOutput`. The delegate method `stream(_:didOutputSampleBuffer:of:)` is called on a background queue and needs `nonisolated`.

## Common Build Errors

### "Cannot find type 'SCDisplay' in scope"
Missing import. Add:
```swift
import ScreenCaptureKit
```

### "#Preview macro not available"
SPM doesn't support `#Preview`. Remove preview blocks or use:
```swift
#if canImport(SwiftUI) && DEBUG && !BUILDING_FOR_SPM
#Preview { ... }
#endif
```

### "Value of optional type must be unwrapped"
Check if you're using `if let` on non-optional Swift 6 properties. Remove the optional binding.

### Sendable closure warnings
FFmpegManager has warnings about captured variables in closures. These are warnings, not errors, and safe for now.

## Post-Build Verification

After making changes, always:

1. **Run `swift build`** - Ensure it compiles
2. **Check for warnings** - Address any new warnings
3. **Test the app** - Launch and verify core functionality:
   - Menu bar icon appears
   - "Record Area" shows selection overlay
   - "Record Window" shows window picker
   - Settings opens preferences
   - Recording creates MOV file
   - GIF export runs (check `~/Library/Application Support/AnimaMac/recordings/`)

## File Locations

- **Source code**: `AnimaMac/`
- **Build output (SPM)**: `.build/debug/AnimaMac`
- **Recordings**: `~/Library/Application Support/AnimaMac/recordings/`
- **FFmpeg binary**: `~/Library/Application Support/AnimaMac/ffmpeg`
