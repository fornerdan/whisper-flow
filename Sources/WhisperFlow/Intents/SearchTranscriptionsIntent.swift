import AppIntents
import WhisperCore

struct SearchTranscriptionsIntent: AppIntent {
    static var title: LocalizedStringResource = "Search Transcriptions"
    static var description: IntentDescription = "Search transcription history by text"

    @Parameter(title: "Search Text")
    var searchText: String

    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<[String]> {
        let records = try DataStore.shared.fetchRecords(searchText: searchText, limit: 10)
        return .result(value: records.map(\.text))
    }
}
