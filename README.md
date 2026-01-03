# AnimaMac

A native macOS GIF recorder inspired by [Gifox](https://gifox.app). Record your screen to high-quality GIFs with no time limits.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 5.9+](https://img.shields.io/badge/Swift-5.9%2B-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **Unlimited Recording** — No 10 or 30-second limits
- **Area Selection** — Drag to select any screen region
- **Window Recording** — Capture specific application windows
- **High-Quality GIFs** — FFmpeg-based encoding with two-pass palette optimization
- **Quality Presets** — Small, Medium, Large, and Original quality options
- **Menubar App** — Lives in your menu bar, no dock icon clutter
- **Auto-Export** — Automatically converts recordings to GIF
- **Clipboard Copy** — GIF copied to clipboard after export

## Requirements

- macOS 14 Sonoma or later
- Screen Recording permission (prompted on first use)

## Installation

### From Source

```bash
# Clone the repository
git clone https://github.com/yourusername/AnimaMac.git
cd AnimaMac

# Build with Swift
swift build

# Or open in Xcode
open AnimaMac.xcodeproj
```

### Build & Run

1. Open `AnimaMac.xcodeproj` in Xcode
2. Select your development team for signing
3. Build and run (⌘R)
4. Grant Screen Recording permission when prompted

## Usage

### Recording

1. Click the record icon in the menu bar
2. Choose **Record Area** or **Record Window**
3. For area recording: drag to select the region, release to start
4. For window recording: select from the list of available windows
5. Press **⌘⎋** (Cmd+Escape) to stop recording

### Settings

Click the gear icon to configure:

- **Recording**: Quality, frame rate, cursor visibility
- **Export**: Quality preset, dithering mode, loop count
- **Storage**: View storage usage, open recordings folder

## Technical Details

### Architecture

```
AnimaMac/
├── App/
│   ├── AnimaMacApp.swift      # MenuBarExtra entry point
│   └── AppState.swift         # Global state management
├── Capture/
│   ├── ScreenRecorder.swift   # ScreenCaptureKit wrapper
│   ├── CaptureConfiguration.swift
│   └── WindowPicker.swift
├── Export/
│   ├── FFmpegManager.swift    # Auto-downloads FFmpeg
│   ├── GIFExporter.swift      # Two-pass palette encoding
│   └── ExportSettings.swift
├── Storage/
│   ├── Recording.swift        # Recording model
│   ├── RecordingLibrary.swift # JSON persistence
│   └── FileManager+AnimaMac.swift
└── UI/
    ├── MenuBarView.swift
    ├── RecordingOverlay.swift
    └── SettingsView.swift
```

### Frameworks

- **SwiftUI** — UI framework
- **ScreenCaptureKit** — Modern screen capture API (macOS 12.3+)
- **AVFoundation** — Video encoding to MOV
- **FFmpeg** — GIF encoding (auto-downloaded on first use)

### GIF Encoding

AnimaMac uses FFmpeg's two-pass palette generation for high-quality GIFs:

```bash
ffmpeg -i input.mov -vf \
  "fps=15,scale=640:-1:flags=lanczos,split[s0][s1]; \
   [s0]palettegen=max_colors=256:stats_mode=diff[p]; \
   [s1][p]paletteuse=dither=sierra2:diff_mode=rectangle" \
  output.gif
```

### Quality Presets

| Preset | FPS | Max Width | Colors | Dither |
|--------|-----|-----------|--------|--------|
| Small | 10 | 480px | 128 | Bayer |
| Medium | 15 | 640px | 256 | Sierra-2 |
| Large | 20 | 1280px | 256 | Floyd-Steinberg |
| Original | 30 | No limit | 256 | Floyd-Steinberg |

### Storage

Recordings are stored in:
```
~/Library/Application Support/AnimaMac/
├── recordings/     # MOV and GIF files
├── library.json    # Recording metadata
└── ffmpeg          # FFmpeg binary (auto-downloaded)
```

## Roadmap

- [ ] Trim/edit recordings before export
- [ ] Cloud upload (Dropbox, Imgur, etc.)
- [ ] Cursor click highlights
- [ ] Keyboard shortcut overlays
- [ ] Global hotkeys
- [ ] MP4/MOV export options

## License

MIT License — see [LICENSE](LICENSE) for details.

## Acknowledgments

- Inspired by [Gifox](https://gifox.app)
- GIF encoding powered by [FFmpeg](https://ffmpeg.org)
- Built with Apple's [ScreenCaptureKit](https://developer.apple.com/documentation/screencapturekit)
