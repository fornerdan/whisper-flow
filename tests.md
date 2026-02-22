# WhisperFlow Tests

**Total: 19 tests across 4 test files**

> Tests require Xcode (not just Command Line Tools) to run via `xcodebuild test -scheme WhisperFlowTests -destination 'platform=macOS'`. SPM `swift test` does not work because XCTest is only available through the Xcode toolchain.

## Test Files

### `Tests/WhisperFlowTests/AudioCaptureTests.swift` (3 tests)

| Test | Description |
|------|-------------|
| `testWhisperSampleRate` | Verifies `AudioCaptureEngine.whisperSampleRate` is 16000 Hz |
| `testWhisperChannelCount` | Verifies `AudioCaptureEngine.whisperChannels` is 1 (mono) |
| `testInitialState` | Verifies a new `AudioCaptureEngine` starts in `.idle` state with audio level 0 |

### `Tests/WhisperFlowTests/TranscriptionEngineTests.swift` (3 tests)

| Test | Description |
|------|-------------|
| `testTranscriptionSegmentProperties` | Verifies `TranscriptionSegment` stores text, startTime, and endTime correctly |
| `testTranscriptionResultProperties` | Verifies `TranscriptionResult` stores text, language, duration, and segments array |
| `testWhisperErrorDescriptions` | Verifies all `WhisperError` cases (`modelLoadFailed`, `contextNotInitialized`, `inferenceFailed`) have non-nil error descriptions with expected content |

### `Tests/WhisperFlowTests/ModelManagerTests.swift` (9 tests)

| Test | Description |
|------|-------------|
| `testModelCatalogContainsExpectedModels` | Catalog includes tiny, base, small, medium, large-v3 |
| `testModelCatalogContainsQuantizedVariants` | Catalog includes q5_0/q5_1 quantized variants |
| `testRecommendedModel` | Recommended model is "base" |
| `testModelLookup` | `ModelCatalog.model(for:)` returns correct model or nil for unknown ID |
| `testModelSpeedComparable` | `ModelSpeed` enum cases are correctly ordered (fastest < slowest) |
| `testModelQualityComparable` | `ModelQuality` enum cases are correctly ordered (basic < best) |
| `testModelsDirectoryExists` | `ModelManager.modelsDirectory` exists on disk |
| `testModelFilenames` | All model filenames match `ggml-*.bin` convention |
| `testDownloadURLsAreValid` | All download URLs point to huggingface.co |

### `Tests/WhisperFlowTests/TextInjectorTests.swift` (4 tests)

| Test | Description |
|------|-------------|
| `testAccessibilityHelperIsTrustedReturnsBool` | `AccessibilityHelper.isTrusted` does not crash (value depends on system state) |
| `testAudioPermissionStatusCases` | `AudioPermissionStatus` has exactly 3 cases: `.granted`, `.denied`, `.notDetermined` |
| `testAudioCaptureErrorDescriptions` | `AudioCaptureError` cases have non-nil error descriptions with expected content |
| `testModelErrorDescription` | `ModelError.modelNotFound` has a non-nil error description containing the model name |

## Coverage Areas

- **Audio Capture** — sample rate, channel count, initial state
- **Transcription** — segment/result data types, error descriptions
- **Model Management** — catalog contents, lookup, speed/quality ordering, file naming, download URLs
- **System Integration** — accessibility trust check, audio permissions, error types
