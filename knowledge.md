# WhisperFlow User Guide

Step-by-step guides for using WhisperFlow on macOS and iOS.

---

## macOS

### First Launch & Onboarding

WhisperFlow shows a 5-step onboarding wizard on first launch:

1. **Welcome** — Overview of features (private, fast, 98+ languages, global hotkey). Click **Get Started**.
2. **Microphone Permission** — Click **Allow Microphone Access** and approve the system prompt. Audio never leaves your device. You can skip this step and grant permission later.
3. **Accessibility Permission** — Click **Grant Accessibility Access**. This opens System Settings > Privacy & Security > Accessibility — toggle **WhisperFlow** ON. This is required for auto-typing transcribed text into other apps. Click **Refresh Status** to confirm, then **Continue**.
4. **Model Download** — Click **Download Base Model (142 MB)** and wait for the progress bar to complete. The Base model offers a good balance of speed and accuracy. You can skip and download a model later from Settings.
5. **Completion** — Shows a quick-start summary. Click **Start Using WhisperFlow**.

### Recording & Transcribing

1. Press **Cmd+Shift+Space** (the default global hotkey) from any app.
2. A floating overlay HUD appears at the top of the screen showing "Recording..."
3. Speak naturally.
4. Press **Cmd+Shift+Space** again to stop recording.
5. The HUD shows "Transcribing..." while the model processes your audio.
6. The transcribed text is automatically:
   - **Typed** into the currently focused app (if auto-inject is enabled and accessibility permission is granted)
   - **Copied** to your clipboard (if clipboard copy is enabled)
   - **Saved** to your transcription history

WhisperFlow also supports **streaming preview** — partial transcription results appear every 3 seconds as you speak, so you can see progress in real time.

### Command Palette Launcher

Press **Cmd+Shift+W** to open the command palette — a Spotlight-style floating panel for quick actions and transcription search.

- **Commands** — Start/Stop/Cancel Recording, Open Settings, Open History. Available commands change based on the current recording state.
- **Search** — Type to search your transcription history. Matching results appear above the commands.
- **Keyboard navigation** — Use Up/Down arrow keys to navigate, Enter to execute, Escape to dismiss.
- **Click-away dismiss** — Clicking anywhere outside the launcher closes it automatically.
- **Copy transcription** — Select a transcription result and press Enter to copy it to the clipboard.

### Dock Presence

By default, WhisperFlow is a menu-bar-only app with no Dock icon. To show it in the Dock:

1. Open **Settings > General**.
2. Enable **Show WhisperFlow in Dock**.
3. The app icon appears in the Dock immediately.
4. Click the Dock icon to open the command palette.
5. Disable the toggle to hide the Dock icon again.

When "Show in Dock" is enabled, closing the Settings or History window does not hide the app from the Dock.

### Shortcuts & Siri Integration

WhisperFlow provides three actions for Shortcuts.app and Siri:

- **Toggle Recording** — Start or stop voice recording. Says "Start recording with WhisperFlow" or "Toggle recording in WhisperFlow".
- **Get Last Transcription** — Returns the text of your most recent transcription. Says "Get last transcription from WhisperFlow".
- **Search Transcriptions** — Search your history by text and returns up to 10 matching results. Says "Search transcriptions in WhisperFlow".

To use these:
1. Open **Shortcuts.app**.
2. Create a new shortcut and search for "WhisperFlow".
3. Add any of the three actions to your shortcut.
4. You can also trigger them via Siri using the phrases listed above.

### Transcription History

Open history from the menu bar dropdown by clicking **History** (or the clock icon).

- **Search** — Use the search bar at the top to filter transcriptions by text content or custom title.
- **Favorites** — Click the star toggle to show only favorited items. Right-click any transcription and choose **Favorite** to mark it.
- **Detail View** — Click a transcription to see the full text, custom title (if set), date, duration, language, model used, and source app.
- **Copy** — Right-click a transcription and choose **Copy Text**, or use the Copy button in the detail view toolbar.
- **Share** — Right-click and choose **Share…** to open the native share sheet, or use the Share button in the detail view toolbar.
- **Rename** — Right-click and choose **Rename…** (or use the Rename button in the detail view toolbar) to give a transcription a custom title. The title appears in the list instead of the raw text. Leave the title empty to revert to showing the original text.
- **Delete** — Right-click a transcription and choose **Delete**.

### Model Management

Manage models from **Settings > Transcription > Model**.

- **Download** — Choose a model from the list and click Download. A progress bar shows download status. Models are downloaded from Hugging Face.
- **Switch** — Select a different downloaded model to use for transcription.
- **Delete** — Remove a downloaded model to free disk space.
- **Recommendations** — The **Base** model (142 MB) is recommended for macOS. Larger models (Small, Medium, Large v3) offer better accuracy but are slower. Quantized variants (Q5_0, Q5_1) reduce download size and RAM usage with minimal quality loss.

Models are stored in `~/Library/Application Support/WhisperFlow/Models/`.

### Settings

Open settings from the menu bar dropdown or via the gear icon.

**General tab:**
- **Launch at login** — Start WhisperFlow automatically when you log in.
- **Show overlay HUD** — Toggle the floating recording/transcribing indicator.
- **Play sounds** — Toggle start/stop sound effects (Tink/Pop).
- **Show in Dock** — Toggle Dock icon visibility. When enabled, clicking the Dock icon opens the command palette.
- **Auto-inject text** — Toggle automatically typing transcribed text into the focused app. Requires Accessibility permission.
- **Copy to clipboard** — Toggle automatically copying transcriptions to the clipboard.

**Transcription tab:**
- **Language** — Choose from 98+ languages or leave on Auto-detect to let the model identify the language.
- **Model** — View the currently loaded model, download new models, or switch between downloaded models.

**Hotkey tab:**
- **Toggle Recording** — Displays the recording hotkey (default: Cmd+Shift+Space).
- **Open Launcher** — Displays the launcher hotkey (default: Cmd+Shift+W).

**About tab:**
- Shows the app version and whisper.cpp acknowledgment.

---

## iOS

### First Launch & Onboarding

WhisperFlow shows a 3-step onboarding flow on first launch:

1. **Welcome** — Overview of the app. Tap **Get Started**.
2. **Microphone Permission** — Tap **Grant Microphone Access** and approve the system prompt. All processing happens on-device. You can skip and grant permission later.
3. **Model Download** — Tap **Download Tiny Model (75 MB)**. The Tiny model is recommended for iPhone — it's fast and works well for most use cases. Tap **Start Using WhisperFlow** when the download completes.

### Recording & Transcribing

1. Open WhisperFlow and go to the **Record** tab.
2. Tap the large **microphone button** to start recording.
3. A waveform visualization shows real-time audio levels as you speak.
4. Tap the microphone button again to stop recording.
5. The transcription appears on screen. You can:
   - **Copy** the text to your clipboard
   - **Share** it with other apps
6. The transcription is saved to your history.

Recording continues briefly if you leave the app (background audio is enabled).

### Setting Up the Keyboard Extension

The WhisperFlow keyboard lets you dictate text directly into any app.

1. Open the iOS **Settings** app.
2. Go to **General > Keyboard > Keyboards**.
3. Tap **Add New Keyboard...**
4. Select **WhisperFlow** from the third-party keyboards list.
5. Tap **WhisperFlow** in your keyboards list and enable **Allow Full Access** (required for the shared container IPC to work).

### Using the Keyboard Extension

1. In any app where you can type (Messages, Notes, Mail, etc.), tap the **globe button** on your current keyboard to switch to the WhisperFlow keyboard.
2. The WhisperFlow keyboard shows a **microphone button** and a **globe button**.
3. Tap the **microphone button** — this automatically opens the WhisperFlow host app for recording.
4. Speak and tap to stop recording in the host app. The text is transcribed on-device.
5. Switch back to the original app. The keyboard reads the transcription from the shared container and **inserts the text automatically** via the text input.
6. Tap the **globe button** to switch back to your regular keyboard.

The keyboard shows a "Waiting for transcription..." status while the host app is recording and processing.

### Model Management

Go to the **Models** tab in the app.

- **Download** — Browse available models and tap to download. A progress bar shows download status.
- **Load** — Select a downloaded model to use for transcription.
- **Delete** — Swipe or tap to remove a downloaded model.
- **iOS-safe models** — Models under 500 MB are marked as safe for iPhone. The Tiny (75 MB) and Base (142 MB) models work best on mobile. Larger models (Medium, Large v3) may exceed available RAM on most iPhones.

### Transcription History

Go to the **History** tab to see all past transcriptions.

- **Search** — Filter transcriptions by text content or custom title.
- **Favorites** — Swipe right on a transcription to toggle favorite, or long-press and choose **Favorite**. Tap the star icon in the toolbar to show only favorites.
- **Detail View** — Tap a transcription to see the full text, custom title (if set), date, duration, language, model used, and source app. The full text is selectable.
- **Copy** — Swipe left to copy, or use the Copy button in the detail view toolbar, or long-press and choose **Copy Text**.
- **Share** — Long-press and choose **Share…** to open the native share sheet, or use the Share button in the detail view toolbar.
- **Rename** — Long-press and choose **Rename…** (or use the Rename button in the detail view toolbar) to give a transcription a custom title. The title appears in the list instead of the raw text. Leave the title empty to revert to showing the original text.
- **Delete** — Swipe left to delete, or long-press and choose **Delete**.

### Settings

Go to the **Settings** tab.

- **Language** — Choose from 28 languages or leave on Auto-detect.
- **Keyboard Extension** — Step-by-step setup instructions for enabling the keyboard (same steps as above).
- **About** — Shows the app version and whisper.cpp engine version (v1.7.4).
