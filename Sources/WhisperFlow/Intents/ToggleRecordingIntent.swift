import AppIntents

struct ToggleRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Recording"
    static var description: IntentDescription = "Start or stop WhisperFlow voice recording"
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        TranscriptionEngine.shared.toggleRecording()
        return .result()
    }
}
