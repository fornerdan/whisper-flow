# WhisperFlow Tests

**Total: 79 tests across 10 test files**

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

### `Tests/WhisperFlowTests/TranscriptionRecordTests.swift` (23 tests)

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
| `testModifiedAtDefaultsToCreatedAt` | New records have `modifiedAt` equal to `createdAt` |
| `testModifiedAtCanBeSetExplicitly` | `modifiedAt` can be set to a custom value via init |
| `testDecodingWithoutModifiedAtField` | Backward compatibility — JSON without `modifiedAt` falls back to `createdAt` |
| `testDecodingWithModifiedAtField` | JSON with `modifiedAt` decodes correctly as a distinct value |
| `testEncodingIncludesModifiedAt` | Encoding includes `modifiedAt` in JSON output |
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

### `Tests/WhisperFlowTests/CloudSyncTests.swift` (10 tests)

| Test | Description |
|------|-------------|
| `testSaveTranscriptionPushesToSyncEngine` | Saving a transcription calls `pushRecord` on the sync engine |
| `testDeleteRecordPushesDeletion` | Deleting a record calls `pushDeletion` on the sync engine |
| `testToggleFavoriteUpdatesModifiedAt` | Toggling favorite updates the record's `modifiedAt` timestamp |
| `testRenameUpdatesModifiedAt` | Renaming a record updates the record's `modifiedAt` timestamp |
| `testMergeRemoteUpsertNewRecord` | Remote record with unknown ID gets inserted into local store |
| `testMergeRemoteUpsertConflictNewerWins` | Remote record with newer `modifiedAt` overwrites local record |
| `testMergeRemoteUpsertConflictLocalWins` | Local record with newer `modifiedAt` is kept over remote |
| `testMergeRemoteDeletion` | Remote deletion removes the corresponding local record |
| `testInitialSyncUploadsAllLocal` | `performInitialSync` receives all local records |
| `testSyncDisabledDoesNotPush` | No sync operations occur when engine `isEnabled` is false |

### `Tests/WhisperFlowTests/UserPreferencesTests.swift` (3 tests)

| Test | Description |
|------|-------------|
| `testShowInDockDefaultsFalse` | `showInDock` defaults to false |
| `testLauncherHotkeyDisplayString` | Returns "⌘⇧W" |
| `testHotkeyDisplayString` | Returns "⌘⇧Space" (regression check) |

## Coverage Areas

- **Audio Capture** — sample rate, channel count, initial state
- **Transcription** — segment/result data types, error descriptions
- **Model Management** — catalog contents, lookup, speed/quality ordering, file naming, download URLs
- **Transcription Record** — title property, displayTitle logic (truncation, first line, fallback), Codable backward compatibility (title, sourceFile, modifiedAt), rename via DataStore, title-aware search
- **System Integration** — accessibility trust check, audio permissions, error types
- **Launcher** — LauncherItem data model, LauncherAction enum cases, LauncherPanel show/hide/toggle lifecycle
- **App Intents** — intent titles, descriptions, parameters, IntentError localization, shortcuts provider count
- **Hotkey Manager** — default key bindings (recording + launcher), callback property access and assignment
- **iCloud Sync** — push on save/delete, modifiedAt updates on mutations, merge logic (new record, conflict newer/older wins, deletion), initial sync upload, disabled engine no-op
- **User Preferences** — dock visibility default, hotkey display strings
