---
name: AnimaMac Conventions & Patterns
description: Project conventions, architecture patterns, and known gotchas for AnimaMac. Use when modifying AnimaMac code, adding features, or debugging issues.
---

# AnimaMac Conventions & Patterns

## Architecture Overview

AnimaMac is a native macOS menu bar app for recording screen to GIF.

```
AnimaMac/
├── App/           # Entry point and global state
├── Capture/       # ScreenCaptureKit recording
├── Export/        # FFmpeg GIF encoding
├── Storage/       # File management and persistence
└── UI/            # SwiftUI views
```

## Key Components

### AppState (App/AppState.swift)
- `@MainActor` ObservableObject holding all app state
- Coordinates recording, export, and UI
- Owns ScreenRecorder, GIFExporter, RecordingLibrary instances

### ScreenRecorder (Capture/ScreenRecorder.swift)
- Wraps ScreenCaptureKit for screen/window capture
- Records to MOV using AVAssetWriter
- **NOT @MainActor** - uses manual thread synchronization
- Frame handling in `SCStreamOutput` must be synchronous to avoid drops

### GIFExporter (Export/GIFExporter.swift)
- Converts MOV to GIF using FFmpeg
- Two-pass palette encoding for quality
- Uses `-filter_complex` NOT `-vf` for the filter graph

### FFmpegManager (Export/FFmpegManager.swift)
- Actor that downloads and manages FFmpeg binary
- Auto-downloads from evermeet.cx on first use
- Stores binary at `~/Library/Application Support/AnimaMac/ffmpeg`

## Critical Patterns

### Screen Recording Permissions
Always check permissions before accessing screen content:
```swift
// Check if permission granted
if ScreenRecorder.hasScreenRecordingPermission {
    // proceed
}

// Request permission
ScreenRecorder.requestScreenRecordingPermission()

// Use ensurePermission() which handles both
try await ScreenRecorder.ensurePermission()
```

After granting permission in System Settings, the app must be relaunched.

### Frame Writing (SCStreamOutput)
The `stream(_:didOutputSampleBuffer:of:)` delegate is called on `videoQueue`, NOT main thread.

**WRONG** - causes frame drops:
```swift
Task { @MainActor in
    // This is async and frames get dropped
    pixelBufferAdaptor?.append(...)
}
```

**CORRECT** - synchronous access:
```swift
DispatchQueue.main.sync {
    // Capture state synchronously
    localVideoInput = self.videoInput
}
// Write on current queue
adaptor.append(imageBuffer, withPresentationTime: time)
```

### FFmpeg Filter Chain
For two-pass palette GIF encoding, use `-filter_complex`:

**WRONG**:
```swift
"-vf", "[0:v]fps=15,scale=640:-2..."  // -vf doesn't support filter graphs
```

**CORRECT**:
```swift
"-filter_complex", "[0:v]fps=15,scale=640:-2:flags=lanczos,split[s0][s1];[s0]palettegen...[p];[s1][p]paletteuse..."
```

### Error Handling in UI
Errors are shown via `AppState.showingError` and `AppState.lastError`:
```swift
catch {
    lastError = error
    showingError = true
}
```

The MenuBarView displays an error view with "Open System Settings" button for permission errors.

## Known Gotchas

1. **Permission caching**: macOS caches screen recording permission per-process. Must relaunch app after granting.

2. **CGRect non-optional**: `SCWindow.frame` is non-optional in Swift 6. Don't use `if let`.

3. **Preview macros**: `#Preview` doesn't work with SPM. Remove or guard with compile-time checks.

4. **FFmpeg progress**: Don't use `-progress pipe:1 -nostats` - it breaks `-filter_complex`. Parse progress from stderr instead.

5. **Scale filter**: Use `-2` instead of `-1` for auto height to ensure even dimensions: `scale=640:-2`

6. **Video bitrate**: Higher bitrate (20Mbps) produces better source for GIF conversion.

7. **FFmpeg architecture**: Must download correct binary for CPU architecture:
   - ARM64 (Apple Silicon): Use `osxexperts.net/ffmpeg7arm.zip`
   - x86_64 (Intel): Use `evermeet.cx/ffmpeg/getrelease/ffmpeg/zip`
   - FFmpegManager uses `#if arch(arm64)` to select correct URL
   - Delete old binary if "bad CPU type" error: `rm ~/Library/Application\ Support/AnimaMac/ffmpeg`

8. **System FFmpeg**: FFmpegManager checks for Homebrew FFmpeg first (`/opt/homebrew/bin/ffmpeg` or `/usr/local/bin/ffmpeg`) before using bundled binary.

## Testing Checklist

When modifying recording/export:
- [ ] Record Area works (drag selection, starts recording)
- [ ] Record Window works (picker shows, recording starts)
- [ ] Cmd+Escape stops recording
- [ ] MOV file created in recordings folder
- [ ] GIF export runs and completes
- [ ] GIF has good quality (no banding, smooth playback)
- [ ] Progress indicator shows during export
- [ ] Errors display properly in UI

## File Paths

| Item | Path |
|------|------|
| App Support | `~/Library/Application Support/AnimaMac/` |
| Recordings | `~/Library/Application Support/AnimaMac/recordings/` |
| Library JSON | `~/Library/Application Support/AnimaMac/library.json` |
| FFmpeg | `~/Library/Application Support/AnimaMac/ffmpeg` |
