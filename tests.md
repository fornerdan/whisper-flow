# WhisperFlow Tests

**Total: 100 tests across 13 test files**

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

### `Tests/WhisperFlowTests/TranscriptionRecordTests.swift` (22 tests)

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
| `testDisplayTitleTruncatesLongText` | `displayTitle` truncates text over 100 chars with "..." |
| `testDisplayTitleDoesNotTruncateExactly100Chars` | `displayTitle` does not truncate text at exactly 100 chars |
| `testDisplayTitlePrefersCustomTitleOverLongText` | Custom title takes precedence over long text |
| `testDecodingWithoutTitleField` | Backward compatibility — JSON without `title` decodes with nil title |
| `testDecodingWithTitleField` | JSON with `title` decodes correctly |
| `testEncodingIncludesTitle` | Encoding includes title in JSON output |
| `testRoundTripEncodingDecoding` | Encode → decode preserves all fields including title |
| `testSourceFileDefaultsToNil` | New records have `sourceFile` as nil by default |
| `testSourceFileCanBeSetViaInit` | `sourceFile` can be set through the initializer |
| `testDecodingWithoutSourceFileField` | Backward compatibility — JSON without `sourceFile` decodes with nil |
| `testEncodingIncludesSourceFile` | Encoding includes `sourceFile` in JSON output |
| `testRenameRecordSetsTitle` | `DataStore.renameRecord` sets title, and clearing with empty string reverts to nil |
| `testSearchMatchesTitle` | `DataStore.fetchRecords` search matches against both title and text |

### `Tests/WhisperFlowTests/TextInjectorTests.swift` (4 tests)

| Test | Description |
|------|-------------|
| `testAccessibilityHelperIsTrustedReturnsBool` | `AccessibilityHelper.isTrusted` does not crash (value depends on system state) |
| `testAudioPermissionStatusCases` | `AudioPermissionStatus` has exactly 3 cases: `.granted`, `.denied`, `.notDetermined` |
| `testAudioCaptureErrorDescriptions` | `AudioCaptureError` cases have non-nil error descriptions with expected content |
| `testModelErrorDescription` | `ModelError.modelNotFound` has a non-nil error description containing the model name |

### `Tests/WhisperFlowTests/LauncherTests.swift` (10 tests)

| Test | Description |
|------|-------------|
| `testLauncherItemHasUniqueId` | Each `LauncherItem` gets a unique UUID |
| `testLauncherItemProperties` | icon, title, subtitle, and action are stored correctly |
| `testLauncherItemWithNilSubtitle` | subtitle can be nil |
| `testLauncherActionCases` | All 6 `LauncherAction` enum cases exist and are distinguishable |
| `testLauncherPanelInitialState` | `isVisible` is false after init |
| `testLauncherPanelShowMakesVisible` | After `show()`, `isVisible` becomes true |
| `testLauncherPanelHideMakesInvisible` | After `show()` then `hide()`, `isVisible` is false |
| `testLauncherPanelToggleFromHidden` | `toggle()` from hidden makes panel visible |
| `testLauncherPanelToggleFromVisible` | `toggle()` from visible hides the panel |
| `testLauncherPanelHideWhenAlreadyHidden` | `hide()` when already hidden is a no-op |

### `Tests/WhisperFlowTests/IntentTests.swift` (10 tests)

| Test | Description |
|------|-------------|
| `testToggleRecordingIntentTitle` | Static title is "Toggle Recording" |
| `testToggleRecordingIntentDescription` | Static description is set |
| `testToggleRecordingIntentOpensApp` | `openAppWhenRun` is true |
| `testGetLastTranscriptionIntentTitle` | Static title is "Get Last Transcription" |
| `testGetLastTranscriptionIntentDescription` | Static description is set |
| `testSearchTranscriptionsIntentTitle` | Static title is "Search Transcriptions" |
| `testSearchTranscriptionsIntentDescription` | Static description is set |
| `testSearchTranscriptionsIntentHasParameter` | `searchText` parameter exists and is settable |
| `testIntentErrorDescription` | `IntentError.noTranscriptions` has localized description "No transcriptions found" |
| `testWhisperFlowShortcutsProviderHasThreeShortcuts` | `appShortcuts` count is 3 |

### `Tests/WhisperFlowTests/HotkeyManagerTests.swift` (4 tests)

| Test | Description |
|------|-------------|
| `testDefaultRecordingHotkey` | keyCode is `kVK_Space`, modifiers is `cmdKey \| shiftKey` |
| `testDefaultLauncherHotkey` | launcherKeyCode is `kVK_ANSI_W`, launcherModifiers is `cmdKey \| shiftKey` |
| `testHotkeyCallbacksAreNilByDefault` | Both `onHotkeyPressed` and `onLauncherHotkeyPressed` are optional closures |
| `testLauncherHotkeyCallbackIsSettable` | Can set and invoke `onLauncherHotkeyPressed` closure |

### `Tests/WhisperFlowTests/UserPreferencesTests.swift` (4 tests)

| Test | Description |
|------|-------------|
| `testShowInDockDefaultsFalse` | `showInDock` defaults to false |
| `testLauncherHotkeyDisplayString` | Returns "⌘⇧W" |
| `testHotkeyDisplayString` | Returns "⌘⇧Space" (regression check) |
| `testTranslateToEnglishDefaultsFalse` | `translateToEnglish` defaults to false |

### `Tests/WhisperFlowTests/HistoryExporterTests.swift` (15 tests)

| Test | Description |
|------|-------------|
| `testExportFormatFileExtensions` | Verifies `.txt`, `.json`, `.csv` file extensions |
| `testExportFormatAllCases` | `ExportFormat` has exactly 3 cases |
| `testPlainTextExportContainsText` | Plain text output contains transcription text, language, and model |
| `testPlainTextExportEmptyRecords` | Empty records export as "No transcriptions.\n" |
| `testPlainTextExportIncludesSourceFile` | Plain text includes "Source File:" when present |
| `testJSONExportIsValidJSON` | JSON output is valid JSON array with correct text field |
| `testJSONExportEmptyRecords` | Empty records export as empty JSON array |
| `testCSVExportHasHeader` | CSV output starts with header row and has correct line count |
| `testCSVExportEmptyRecords` | Empty records export as header-only CSV |
| `testCSVEscapesCommasInText` | Text containing commas is properly quoted |
| `testCSVEscapesQuotesInText` | Double quotes in text are doubled and field is quoted |
| `testCSVEscapesNewlinesInText` | Newlines in text are preserved within quoted field |
| `testCsvEscapeNoSpecialChars` | Plain text passes through unescaped |
| `testCsvEscapeWithComma` | Comma triggers quoting |
| `testCsvEscapeWithQuotes` | Quotes are doubled and field is quoted |

### `Tests/WhisperFlowTests/AudioFileLoaderTests.swift` (7 tests)

| Test | Description |
|------|-------------|
| `testSupportedExtensions` | `supportedExtensions` matches expected set (wav, mp3, m4a, aac, flac, mp4, mov, caf, aiff, aif) |
| `testIsSupportedReturnsTrueForKnownFormats` | Known formats (wav, mp3, m4a, MP4, FLAC) return true (case-insensitive) |
| `testIsSupportedReturnsFalseForUnknownFormats` | Unknown formats (txt, pdf, ogg, empty) return false |
| `testLoadSamplesThrowsForUnsupportedFormat` | Loading `.ogg` throws `AudioFileError.unsupportedFormat("ogg")` |
| `testLoadSamplesThrowsForMissingFile` | Loading nonexistent `.wav` throws `AudioFileError.fileNotFound` |
| `testMaxDurationIs30Minutes` | `maxDuration` is 1800 seconds |
| `testErrorDescriptions` | Error cases have correct localized descriptions |

### `Tests/WhisperFlowTests/AutoDeleteTests.swift` (4 tests)

| Test | Description |
|------|-------------|
| `testPurgeDeletesOldRecords` | Freshly saved records survive a 30-day retention purge |
| `testPurgeKeepsRecentRecords` | Recently created record is not purged with 7-day retention |
| `testPurgeWithZeroRetentionKeepsAll` | `retentionDays: 0` (keep forever) does not delete any records |
| `testPurgeWithNegativeRetentionKeepsAll` | Negative retention days treated as no-op |

### `Tests/WhisperFlowTests/AudioDeviceTests.swift` (5 tests, macOS only)

| Test | Description |
|------|-------------|
| `testAudioDeviceManagerInitializes` | `AudioDeviceManager` initializes without crashing even with no devices |
| `testAudioDeviceManagerDefaultConsistency` | At most one device is marked as default |
| `testRefreshDevicesPopulatesUIDs` | All enumerated devices have non-empty UID and name |
| `testRefreshDevicesIsIdempotent` | Consecutive `refreshDevices()` calls return the same result |
| `testStartRecordingWithInvalidDeviceThrows` | Invalid device UID throws `AudioCaptureError.deviceNotFound` |

## Coverage Areas

- **Audio Capture** — sample rate, channel count, initial state
- **Audio Device Selection** — device enumeration, default detection, UID validation, invalid device error handling (macOS)
- **Audio File Import** — supported extensions, case-insensitive lookup, error cases (unsupported format, missing file), max duration, error descriptions
- **Transcription** — segment/result data types, error descriptions
- **Model Management** — catalog contents, lookup, speed/quality ordering, file naming, download URLs
- **Transcription Record** — title property, displayTitle logic (truncation, first line, fallback), Codable backward compatibility (title, sourceFile), rename via DataStore, title-aware search
- **History Export** — format file extensions, all three export formats (plain text, JSON, CSV), empty record handling, CSV escaping (commas, quotes, newlines)
- **Auto-delete History** — retention purge with various retention days (0, negative, 7, 30), record survival verification
- **System Integration** — accessibility trust check, audio permissions, error types
- **Launcher** — LauncherItem data model, LauncherAction enum cases, LauncherPanel show/hide/toggle lifecycle
- **App Intents** — intent titles, descriptions, parameters, IntentError localization, shortcuts provider count
- **Hotkey Manager** — default key bindings (recording + launcher), callback property access and assignment
- **User Preferences** — dock visibility default, hotkey display strings, translate default
