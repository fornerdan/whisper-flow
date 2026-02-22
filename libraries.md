# WhisperFlow Libraries & Dependencies

All dependencies used by WhisperFlow across macOS and iOS.

## External Libraries

| Library | Version | License | Platform | Description |
|---------|---------|---------|----------|-------------|
| [whisper.cpp](https://github.com/ggerganov/whisper.cpp) | v1.7.4 | MIT | macOS, iOS | Speech-to-text inference engine. Built as a static xcframework via CMake with Metal GPU acceleration enabled. |
| [ggml](https://github.com/ggerganov/ggml) | bundled with whisper.cpp | MIT | macOS, iOS | Tensor computation library. Provides CPU, Metal, and BLAS backends for model inference. Linked as `libggml`, `libggml-base`, `libggml-cpu`, `libggml-metal`, `libggml-blas`. |
| [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) | 2.0.0+ | MIT | macOS | Global hotkey handling (declared in `project.yml` as an SPM dependency for the Xcode project). |

## Apple Frameworks

System frameworks — no separate license required.

| Framework | Platform | Usage |
|-----------|----------|-------|
| AVFoundation | macOS, iOS | Audio capture (16 kHz mono PCM recording) and audio session management |
| Accelerate | macOS, iOS | Linear algebra and signal processing optimizations for inference |
| Metal | macOS, iOS | GPU compute for whisper.cpp via the GGML Metal backend |
| MetalKit | macOS, iOS | Metal rendering utilities |
| CoreML | macOS, iOS | Linked framework (available for future CoreML model support) |
| Foundation | macOS, iOS | Standard data types, file I/O, networking, JSON encoding |
| SwiftUI | macOS, iOS | Declarative UI for all views (settings, onboarding, history, etc.) |
| Combine | macOS, iOS | Reactive state management in view models |
| AppKit | macOS | Native macOS window management (NSWindow, NSPanel, menu bar extra) |
| Carbon | macOS | Global hotkey registration via `HIToolbox` event APIs |
| ServiceManagement | macOS | Launch at login functionality |
| UIKit | iOS | iOS UI framework, keyboard extension (`UIInputViewController`) |
| UserNotifications | iOS | Local notification support |

## Build Tools

| Tool | Purpose |
|------|---------|
| [CMake](https://cmake.org) | Builds whisper.cpp from source for macOS, iOS, and iOS Simulator targets |
| [xcodegen](https://github.com/yonaskolb/XcodeGen) | Generates `WhisperFlow.xcodeproj` from `project.yml` |
| libtool | Combines individual static libraries (`libwhisper.a`, `libggml*.a`) into a single combined archive per platform |
| xcodebuild | Creates the multi-platform `whisper.xcframework` from per-platform static archives |
| Swift Package Manager | Resolves SPM dependencies (KeyboardShortcuts) and supports building via `swift build` |

## Model Hosting

Whisper GGML models are downloaded at runtime from [Hugging Face](https://huggingface.co/ggerganov/whisper.cpp):

```
https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-{model}.bin
```

10 models available (Tiny, Tiny Q5_0, Base, Base Q5_0, Small, Small Q5_1, Medium, Medium Q5_0, Large v3, Large v3 Q5_0). See `features.md` for the full model table with sizes, RAM usage, and platform recommendations.

## C/C++ Runtime

| Library | Purpose |
|---------|---------|
| libc++ | C++ standard library, required by whisper.cpp |
