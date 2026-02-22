import Foundation

@MainActor
public final class DataStore {
    public static let shared = DataStore()

    private let fileURL: URL
    private var records: [TranscriptionRecord] = []

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let whisperFlowDir = appSupport.appendingPathComponent("WhisperFlow", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: whisperFlowDir, withIntermediateDirectories: true)

        fileURL = whisperFlowDir.appendingPathComponent("history.json")

        // Load existing records
        loadFromDisk()
    }

    // MARK: - Persistence

    private func loadFromDisk() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            records = []
            return
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            records = try decoder.decode([TranscriptionRecord].self, from: data)
        } catch {
            print("Failed to load transcription history: \(error)")
            records = []
        }
    }

    private func saveToDisk() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(records)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save transcription history: \(error)")
        }
    }

    // MARK: - Save

    /// Save a transcription record. Pass sourceApp explicitly — on macOS, callers
    /// can get this from NSWorkspace; on iOS, pass nil or the deep-link source.
    public func saveTranscription(
        text: String,
        language: String,
        duration: TimeInterval,
        modelUsed: String,
        sourceApp: String? = nil
    ) async {
        let record = TranscriptionRecord(
            text: text,
            language: language,
            duration: duration,
            modelUsed: modelUsed,
            sourceApp: sourceApp
        )

        records.insert(record, at: 0)
        saveToDisk()
    }

    // MARK: - Fetch

    public func fetchRecords(
        searchText: String = "",
        favoritesOnly: Bool = false,
        limit: Int? = nil
    ) throws -> [TranscriptionRecord] {
        var result = records

        // Sort by date descending (most recent first)
        result.sort { $0.createdAt > $1.createdAt }

        // Filter by favorites
        if favoritesOnly {
            result = result.filter { $0.isFavorite }
        }

        // Filter by search text (matches title and text)
        if !searchText.isEmpty {
            result = result.filter {
                $0.text.localizedCaseInsensitiveContains(searchText)
                || ($0.title?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }

        // Apply limit
        if let limit {
            result = Array(result.prefix(limit))
        }

        return result
    }

    // MARK: - Delete

    public func deleteRecord(_ record: TranscriptionRecord) throws {
        records.removeAll { $0.id == record.id }
        saveToDisk()
    }

    public func deleteAllRecords() throws {
        records.removeAll()
        saveToDisk()
    }

    // MARK: - Toggle Favorite

    public func toggleFavorite(_ record: TranscriptionRecord) throws {
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index].isFavorite.toggle()
            saveToDisk()
        }
    }

    // MARK: - Rename

    public func renameRecord(_ record: TranscriptionRecord, title: String) throws {
        if let index = records.firstIndex(where: { $0.id == record.id }) {
            records[index].title = title.isEmpty ? nil : title
            saveToDisk()
        }
    }
}
