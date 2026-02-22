import AppIntents
import WhisperCore

struct GetLastTranscriptionIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Last Transcription"
    static var description: IntentDescription = "Returns the text of the most recent transcription"

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let records = try DataStore.shared.fetchRecords(limit: 1)
        guard let latest = records.first else {
            throw IntentError.noTranscriptions
        }
        return .result(value: latest.text)
    }
}
