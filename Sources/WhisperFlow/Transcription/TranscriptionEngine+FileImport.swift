import Foundation
import AppKit
import UniformTypeIdentifiers
import WhisperCore

extension TranscriptionEngine {

    /// Transcribe an audio file and save the result to history.
    func transcribeFile(url: URL) async {
        guard whisperContext != nil else {
            state = .error("No model loaded. Please download a model first.")
            return
        }

        state = .transcribing

        do {
            let samples = try AudioFileLoader.loadSamples(from: url)

            let prefs = UserPreferences.shared
            let language = prefs.language == "auto" ? nil : prefs.language

            guard let context = whisperContext else {
                state = .error("No model loaded")
                return
            }

            let result = try await context.transcribe(
                samples: samples,
                language: language,
                translate: prefs.translateToEnglish
            )

            let text = result.text
            currentText = text
            state = .done(text)

            // Save to history with source file info
            await DataStore.shared.saveTranscription(
                text: text,
                language: result.language,
                duration: result.duration,
                modelUsed: ModelManager.shared.selectedModelKey,
                sourceFile: url.lastPathComponent
            )

            // Copy to clipboard if enabled
            if prefs.copyToClipboard {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
            }

        } catch {
            state = .error("File transcription failed: \(error.localizedDescription)")
        }
    }

    /// Present a file picker and transcribe the selected file.
    func importAndTranscribeFile() {
        let panel = NSOpenPanel()
        panel.title = "Import Audio File"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = AudioFileLoader.supportedExtensions.compactMap { ext in
            UTType(filenameExtension: ext)
        }

        guard panel.runModal() == .OK, let url = panel.url else { return }

        Task {
            await transcribeFile(url: url)
        }
    }
}
