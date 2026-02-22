# WhisperFlow

On-device speech-to-text for macOS and iOS, powered by [whisper.cpp](https://github.com/ggerganov/whisper.cpp). Private, fast, works offline.

## Features

- **100% on-device** — audio never leaves your machine
- **Metal GPU acceleration** — fast inference on Apple Silicon and Intel Macs
- **98+ languages** with auto-detection
- **10 Whisper models** — from Tiny (75 MB) to Large v3 (2.9 GB), including quantized variants
- **Streaming preview** — see partial transcriptions as you speak
- **Searchable history** with favorites and source app tracking

### macOS

- Global hotkey (Cmd+Shift+Space) works in any app
- **Command palette launcher** (Cmd+Shift+W) — Spotlight-style quick actions and transcription search
- Auto-types transcribed text into the focused app via accessibility APIs
- Auto-copies to clipboard
- Menu bar app with optional **Dock presence** toggle
- Floating overlay HUD shows recording/transcribing state
- **Shortcuts.app & Siri integration** — Toggle Recording, Get Last Transcription, Search Transcriptions
- Launch at login

### iOS

- Tap-to-record with real-time waveform visualization
- Custom keyboard extension — dictate text into any app
- App Group IPC with Darwin notifications for keyboard-to-app communication
- Deep link support (`whisperflow://record`)
- Background audio recording

## Requirements

- **macOS** 14.0+ (Sonoma)
- **iOS** 16.0+
- **Xcode** 15.0+ (for building)
- **CMake** (for building whisper.cpp)

## Getting Started

### 1. Clone and set up

```bash
git clone <repo-url>
cd WhisperFlow
./scripts/setup.sh
```

The setup script:
1. Clones whisper.cpp v1.7.4 and builds it as a multi-platform xcframework (macOS, iOS, iOS Simulator) with Metal enabled
2. Generates the Xcode project via xcodegen (if installed)
3. Downloads the Tiny test model (75 MB) to `~/Library/Application Support/WhisperFlow/Models/`

### 2. Build and run

**Option A — Xcode (recommended for iOS):**

```bash
open WhisperFlow.xcodeproj
```

Select the `WhisperFlow` scheme for macOS or `WhisperFlowiOS` for iOS, then Build & Run (Cmd+R).

**Option B — Swift Package Manager (macOS only):**

```bash
swift build
```

### 3. Grant permissions

- **Microphone** — prompted on first recording attempt
- **Accessibility** (macOS only) — required for auto-typing text into other apps. Grant in System Settings > Privacy & Security > Accessibility.
- **Keyboard** (iOS only) — enable the WhisperFlow keyboard in Settings > General > Keyboard > Keyboards > Add New Keyboard

## Project Structure

```
WhisperFlow/
├── Sources/
│   ├── WhisperBridge/       # C bridge to whisper.cpp headers
│   ├── WhisperCore/         # Shared library (macOS + iOS)
│   │   ├── Audio/           # AVFoundation 16 kHz mono capture
│   │   ├── Transcription/   # WhisperContext, StreamingTranscriber
│   │   ├── Models/          # ModelCatalog, ModelManager
│   │   ├── Persistence/     # JSON-backed transcription history
│   │   └── IPC/             # App Group shared container
│   ├── WhisperFlow/         # macOS app (menu bar extra + launcher + intents)
│   ├── WhisperFlowiOS/      # iOS host app (tab-based)
│   └── WhisperKeyboard/     # iOS keyboard extension
├── Tests/
├── Vendor/
│   └── whisper.xcframework/ # Pre-built whisper.cpp
├── scripts/
│   └── setup.sh             # Build xcframework + generate project
├── Package.swift            # SPM manifest
├── project.yml              # xcodegen config
├── features.md              # Feature matrix and detailed specs
├── libraries.md             # Dependencies and licenses
└── knowledge.md             # User guide
```

## Whisper Models

Models are downloaded at runtime from [Hugging Face](https://huggingface.co/ggerganov/whisper.cpp).

| Model | Size | RAM | Speed | Quality | iOS Safe |
|-------|------|-----|-------|---------|:--------:|
| Tiny | 75 MB | ~273 MB | Fastest | Basic | Yes |
| Tiny (Q5_0) | 32 MB | ~150 MB | Fastest | Basic | Yes |
| Base | 142 MB | ~388 MB | Fast | Good | Yes |
| Base (Q5_0) | 57 MB | ~200 MB | Fast | Good | Yes |
| Small | 466 MB | ~852 MB | Medium | Great | Yes |
| Small (Q5_1) | 190 MB | ~500 MB | Medium | Great | Yes |
| Medium | 1.5 GB | ~2.1 GB | Slow | Excellent | No |
| Medium (Q5_0) | 539 MB | ~1.0 GB | Slow | Excellent | No |
| Large v3 | 2.9 GB | ~3.9 GB | Slowest | Best | No |
| Large v3 (Q5_0) | 1.1 GB | ~1.8 GB | Slowest | Best | No |

**Defaults:** Base (macOS), Tiny (iOS). Models marked "iOS Safe" are under 500 MB and fit comfortably in iPhone RAM.

## Documentation

- **[features.md](features.md)** — Detailed feature matrix and technical specs
- **[libraries.md](libraries.md)** — All dependencies with URLs and licenses
- **[knowledge.md](knowledge.md)** — Step-by-step user guide for macOS and iOS

## Acknowledgments

- [whisper.cpp](https://github.com/ggerganov/whisper.cpp) by Georgi Gerganov (MIT License)
- [ggml](https://github.com/ggerganov/ggml) by Georgi Gerganov (MIT License)
- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) by Sindre Sorhus (MIT License)
