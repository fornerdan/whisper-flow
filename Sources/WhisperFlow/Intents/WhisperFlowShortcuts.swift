import AppIntents

enum IntentError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case noTranscriptions

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noTranscriptions:
            return "No transcriptions found"
        }
    }
}

struct WhisperFlowShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ToggleRecordingIntent(),
            phrases: [
                "Start recording with \(.applicationName)",
                "Toggle recording in \(.applicationName)"
            ],
            shortTitle: "Toggle Recording",
            systemImageName: "mic.fill"
        )

        AppShortcut(
            intent: GetLastTranscriptionIntent(),
            phrases: [
                "Get last transcription from \(.applicationName)",
                "What did I just say in \(.applicationName)"
            ],
            shortTitle: "Last Transcription",
            systemImageName: "doc.text"
        )

        AppShortcut(
            intent: SearchTranscriptionsIntent(),
            phrases: [
                "Search transcriptions in \(.applicationName)",
                "Find transcription in \(.applicationName)"
            ],
            shortTitle: "Search Transcriptions",
            systemImageName: "magnifyingglass"
        )
    }
}
