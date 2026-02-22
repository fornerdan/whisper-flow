# WhisperFlow Tests

**Total: 37 tests across 5 test files**

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

### `Tests/WhisperFlowTests/TranscriptionRecordTests.swift` (18 tests)

| Test | Description |
|------|-------------|
| `testTitleDefaultsToNil` | New records have `title` as nil by default |
| `testTitleCanBeSetViaInit` | Title can be set through the initializer |
| `testTitleIsMutable` | Title can be mutated after creation |
| `testTitleCanBeClearedToNil` | Title can be set back to nil |
| `testDisplayTitleReturnsTitleWhenSet` | `displayTitle` returns custom title when set |
| `testDisplayTitleReturnsTextWhenNoTitle` | `displayTitle` falls back to text when no title |
| `testDisplayTitleReturnsTextWhenTitleIsEmpty` | `displayTitle` falls back to text when title is empty string |
| `testDisplayTitleReturnsFirstLineOnly` | `displayTitle` returns only the first line of multi-line text |
| `testDisplayTitleHandlesCarriageReturn` | `displayTitle` handles `\r\n` line endings |
| `testDisplayTitleTruncatesLongText` | `displayTitle` truncates text over 100 chars with "…" |
| `testDisplayTitleDoesNotTruncateExactly100Chars` | `displayTitle` does not truncate text at exactly 100 chars |
| `testDisplayTitlePrefersCustomTitleOverLongText` | Custom title takes precedence over long text |
| `testDecodingWithoutTitleField` | Backward compatibility — JSON without `title` decodes with nil title |
| `testDecodingWithTitleField` | JSON with `title` decodes correctly |
| `testEncodingIncludesTitle` | Encoding includes title in JSON output |
| `testRoundTripEncodingDecoding` | Encode → decode preserves all fields including title |
| `testRenameRecordSetsTitle` | `DataStore.renameRecord` sets title, and clearing with empty string reverts to nil |
| `testSearchMatchesTitle` | `DataStore.fetchRecords` search matches against both title and text |

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
- **Transcription Record** — title property, displayTitle logic (truncation, first line, fallback), Codable backward compatibility, rename via DataStore, title-aware search
- **System Integration** — accessibility trust check, audio permissions, error types
