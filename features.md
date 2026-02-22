# WhisperFlow Features

On-device speech-to-text powered by [whisper.cpp](https://github.com/ggerganov/whisper.cpp). Private, fast, works offline.

## Platform Overview

| Feature | macOS | iOS |
|---------|:-----:|:---:|
| On-device transcription (whisper.cpp) | Yes | Yes |
| Metal GPU acceleration | Yes | Yes |
| 98+ languages | Yes | Yes |
| Translate any language to English | Yes | Yes |
| Model download & management | Yes | Yes |
| Transcription history | Yes | Yes |
| iCloud sync (CloudKit) | Yes | Yes |
| History export (Plain Text, JSON, CSV) | Yes | Yes |
| Audio file import (wav, mp3, m4a, etc.) | Yes | - |
| Copy to clipboard | Yes | Yes |
| Share transcription (native share sheet) | Yes | Yes |
| Rename transcription (custom title) | Yes | Yes |
| Full transcription detail view | Yes | Yes |
| Offline operation | Yes | Yes |
| Global hotkey (Cmd+Shift+Space) | Yes | - |
| Command palette launcher (Cmd+Shift+W) | Yes | - |
| Auto-type into focused app | Yes | - |
| Menu bar app (optional Dock icon) | Yes | - |
| Floating overlay HUD | Yes | - |
| Shortcuts.app & Siri integration | Yes | - |
| Custom keyboard extension | - | Yes |
| Deep link recording (whisperflow://) | - | Yes |
| Keyboard → host app IPC | - | Yes |

## macOS App

WhisperFlow lives in the menu bar and works system-wide.

### Recording & Transcription
- **Global hotkey** — Press Cmd+Shift+Space anywhere to start/stop recording
- **Auto text injection** — Transcribed text is typed directly into the focused app via accessibility APIs
- **Clipboard integration** — Transcription automatically copied to clipboard
- **Streaming preview** — Real-time partial transcription as you speak (3-second chunks)
- **Sound feedback** — Tink/Pop sounds on start/stop (configurable)
- **Translation mode** — Translate speech in any language to English using whisper.cpp's built-in translation. Toggle in menu bar, launcher, or Settings
- **Audio file import** — Transcribe audio/video files (wav, mp3, m4a, aac, flac, mp4, mov, caf, aiff) via file picker. Max 30 minutes. Source file name tracked in history

### User Interface
- **Menu bar extra** — Compact window with status, last transcription, and quick actions
- **Command palette launcher** — Spotlight-style panel (Cmd+Shift+W) for quick actions and transcription search with keyboard navigation. Includes: Start/Stop/Cancel Recording, Import Audio File, Toggle Translation, Export History, Open Settings, Open History
- **Floating overlay HUD** — Recording/transcribing indicator positioned at top of screen
- **Optional Dock icon** — Toggle "Show in Dock" in Settings; clicking the Dock icon opens the launcher
- **Transcription history** — Searchable list with favorites, source app tracking, detail view, custom titles (rename), native sharing, and export
- **History export** — Export transcriptions as Plain Text, JSON, or CSV. Choose scope: All, Favorites Only, or Date Range. Via toolbar button or launcher command
- **Settings panel** — General, Transcription, Hotkey, and About tabs

### Model Management
- 10 Whisper models available (Tiny through Large v3, plus quantized variants)
- Default recommendation: **Base** (142 MB) — good balance of speed and accuracy
- Download progress tracking, load/unload, delete

### iCloud Sync
- **CloudKit private database** — transcription history syncs across all devices signed into the same iCloud account
- **On by default** — toggle "Sync with iCloud" in Settings > General
- **Sync status** — Settings shows last synced timestamp
- **Offline resilience** — changes queue locally (pending upload/deletion) and sync when connectivity returns
- **Conflict resolution** — last-write-wins based on `modifiedAt` timestamp
- **Push notifications** — CKDatabaseSubscription triggers near-instant sync when remote changes occur
- **Foreground fetch** — also fetches changes every time the app becomes active, as a fallback
- **Initial sync** — on first enable, all existing local records are uploaded in batches
- **Custom zone** — uses `TranscriptionHistory` CKRecordZone for incremental change token tracking
- **iCloud container** — `iCloud.com.whisperflow.app` (shared between macOS and iOS)

### System Integration
- Launch at login (via ServiceManagement)
- Accessibility permission for text injection (CGEvent keystrokes + clipboard paste)
- Hardened runtime with sandbox entitlements (audio input, user-selected files read-only, network client)
- Privacy manifest (`PrivacyInfo.xcprivacy`) — no tracking, no data collection, required-reason API declarations
- Document type declarations for audio file import UTTypes
- **Shortcuts.app integration** — Three AppIntents: Toggle Recording, Get Last Transcription, Search Transcriptions
- **Siri support** — Voice phrases to trigger recording or retrieve transcriptions

## iOS App

WhisperFlow for iOS provides a standalone recording app and a custom keyboard extension for speech-to-text anywhere.

### Host App
- **Tab-based UI** — Record, History, Models, Settings
- **Large mic button** — Tap to record, tap again to stop and transcribe
- **Waveform visualization** — Real-time audio level display during recording
- **Transcription results** — View, copy, or send to keyboard extension
- **Background audio** — Recording continues when leaving the app briefly

### Keyboard Extension
- **Minimal dictation keyboard** — Not a full QWERTY replacement, just a mic trigger
- **One-tap recording** — Mic button deep-links to host app (`whisperflow://record`)
- **Auto text insertion** — When you return to the original app, transcribed text is inserted automatically via `textDocumentProxy`
- **Status indicator** — Shows "Waiting for transcription..." while recording in host app
- **Globe button** — Switch back to the system keyboard

### IPC (Inter-Process Communication)
- **App Group shared container** — Host app writes transcription to shared UserDefaults
- **Darwin notifications** — Real-time notification from host app to keyboard extension
- **Fallback polling** — Keyboard checks shared container on appear (in case notification was missed)
- **5-minute TTL** — Expired transcriptions are automatically discarded

### Model Management
- iOS-optimized model recommendations (models under 500 MB)
- Default recommendation: **Tiny** (75 MB) — fast, fits comfortably in iPhone RAM
- Memory warnings for larger models
- Download, load, and delete from within the app

### Onboarding
- 3-step setup: Welcome → Microphone permission → Model download
- Keyboard enable instructions in Settings tab

### User Flow (Keyboard → Transcription → Text)
1. User is typing in any app (Messages, Notes, etc.)
2. Switches to WhisperFlow keyboard (globe button)
3. Taps mic button → host app opens automatically
4. Speaks, taps "Done"
5. Host app transcribes, writes to shared container
6. User switches back to original app
7. Keyboard reads transcription and inserts text

## Shared Core (WhisperCore)

Both platforms share a common library:

- **AudioCaptureEngine** — AVFoundation-based 16kHz mono capture with format conversion
- **AudioFileLoader** — Load audio/video files (wav, mp3, m4a, aac, flac, mp4, mov, caf, aiff) and convert to 16kHz mono Float32 samples via AVAudioFile + AVAudioConverter. 30-minute max duration guard
- **WhisperContext** — whisper.cpp C API wrapper with async inference and built-in translation support
- **StreamingTranscriber** — Chunked real-time transcription with overlap
- **ModelCatalog** — 10 model definitions with platform-aware recommendations
- **ModelManager** — Download, load, delete with progress tracking (decoupled via `ModelLoadHandler` protocol)
- **DataStore** — JSON-backed transcription history with search, favorites, rename, pagination, and optional CloudKit sync
- **TranscriptionRecord** — Data model (text, language, duration, model, source app, source file, favorite, optional title with displayTitle computed property, modifiedAt for sync conflict resolution)
- **CloudSyncEngine** — Protocol + `CKCloudSyncEngine` implementation for iCloud sync via CloudKit private database (custom zone, change tokens, batch operations, CKSubscription)
- **SyncMetadataStore** — Tracks pending uploads/deletions and persists CKServerChangeToken for incremental fetches
- **HistoryExporter** — Export transcription records as Plain Text, JSON, or CSV with proper quoting/escaping
- **SharedContainer** — App Group UserDefaults + Darwin notification IPC

## Whisper Models

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

## Requirements

- **macOS**: 14.0+ (Sonoma), Microphone + Accessibility permissions
- **iOS**: 16.0+, Microphone permission, keyboard "Allow Full Access" for extension
- **Apple Developer Account**: Required for App Group entitlement (iOS keyboard IPC) and iCloud/CloudKit entitlement (sync)
- **iCloud Account**: Required for cross-device sync (signed in on each device)
