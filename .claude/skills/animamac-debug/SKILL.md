---
name: AnimaMac Debugging
description: Debug common AnimaMac issues including permissions, recording failures, GIF export problems, and UI issues. Use when the app isn't working correctly or when troubleshooting errors.
---

# AnimaMac Debugging

## Quick Diagnosis

### App won't record
1. Check screen recording permission: System Settings > Privacy & Security > Screen Recording
2. Ensure AnimaMac is in the list and enabled
3. **Quit and relaunch the app** after enabling permission

### GIF not created (only MOV)
Check FFmpeg:
```bash
# Is FFmpeg downloaded?
ls ~/Library/Application\ Support/AnimaMac/ffmpeg

# Test FFmpeg manually
~/Library/Application\ Support/AnimaMac/ffmpeg -version
```

Check export logs in console output for `[GIFExporter]` and `[FFmpeg]` messages.

### Poor quality GIF
- Check source MOV quality first
- Verify filter chain uses `-filter_complex` not `-vf`
- Check bitrate in ScreenRecorder.swift (should be 20_000_000)

## Debug Commands

### View Recent Recordings
```bash
ls -la ~/Library/Application\ Support/AnimaMac/recordings/
```

### Check Recording Library
```bash
cat ~/Library/Application\ Support/AnimaMac/library.json | python3 -m json.tool
```

### Test FFmpeg Manually
```bash
# Test GIF conversion
~/Library/Application\ Support/AnimaMac/ffmpeg \
  -y -i input.mov \
  -filter_complex "[0:v]fps=15,scale=640:-2:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=256:stats_mode=diff[p];[s1][p]paletteuse=dither=sierra2:diff_mode=rectangle" \
  -loop 0 output.gif
```

### Reset FFmpeg
```bash
rm ~/Library/Application\ Support/AnimaMac/ffmpeg
# App will re-download on next export
```

### Clear All Data
```bash
rm -rf ~/Library/Application\ Support/AnimaMac/
# WARNING: Deletes all recordings
```

## Common Issues

### "Permission Required" keeps appearing

**Cause**: Screen recording permission not granted or app not relaunched.

**Fix**:
1. Open System Settings > Privacy & Security > Screen Recording
2. Enable AnimaMac (add if not listed)
3. **Quit the app completely** (not just close menu)
4. Relaunch AnimaMac

**Why**: macOS caches permission state at process start. Must relaunch to pick up changes.

### "Record Area" does nothing

**Cause**: Could be permission issue or overlay not showing.

**Debug**:
1. Check console for "No displays available" or "Failed to get displays"
2. If permission error, see above
3. If overlay issue, check `OverlayWindowController` is initialized in `AppState.setupComponents()`

### Recording stops immediately

**Cause**: Frame writing failure or AVAssetWriter error.

**Debug**:
1. Check for errors in `SCStreamDelegate.stream(_:didStopWithError:)`
2. Verify `videoInput.isReadyForMoreMediaData` is being checked
3. Check disk space in recordings directory

### GIF export fails silently

**Cause**: FFmpeg command error not displayed.

**Debug**:
1. Look for `[GIFExporter]` and `[FFmpeg]` log messages
2. Check `FFmpegError.executionFailed` error message
3. Try manual FFmpeg command (see above)

Common FFmpeg errors:
- "No such filter" - filter chain syntax error
- "Output file is empty" - input file issue
- "Permission denied" - FFmpeg binary not executable

### Menu bar icon missing

**Cause**: App not running or MenuBarExtra issue.

**Debug**:
1. Check Activity Monitor for AnimaMac process
2. Look for crashes in Console.app
3. Verify `@main` entry point in AnimaMacApp.swift

### Settings won't open

**Cause**: `@Environment(\.openSettings)` not working.

**Fix**: Ensure using `openSettingsAction()` not deprecated selector-based approach.

## Adding Debug Logging

To add logging for troubleshooting:

```swift
// In ScreenRecorder
print("[ScreenRecorder] Starting capture for display: \(display.displayID)")

// In GIFExporter
print("[GIFExporter] Filter chain: \(filterChain)")

// In FFmpegManager
print("[FFmpeg] Exited with code: \(exitCode)")
print("[FFmpeg] Error output: \(errorStr)")
```

## Inspecting State

Key AppState properties to check:
- `isRecording` - should be true during recording
- `isExporting` - should be true during GIF creation
- `showingError` / `lastError` - error state
- `selectedDisplay` / `selectedWindow` - what's being recorded

## Recovery Steps

If app is in bad state:

1. Stop any recording: Cmd+Escape
2. Quit app completely
3. Delete corrupted recordings if needed
4. Relaunch app

If still broken:
```bash
# Nuclear option - reset everything
rm -rf ~/Library/Application\ Support/AnimaMac/
# Relaunch app - will recreate directories
```
