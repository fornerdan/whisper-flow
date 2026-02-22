import Foundation
import SwiftData
import AppKit

@MainActor
final class DataStore {
    static let shared = DataStore()

    let container: ModelContainer

    private init() {
        do {
            let schema = Schema([TranscriptionRecord.self])
            let config = ModelConfiguration(
                "WhisperFlow",
                schema: schema,
                isStoredInMemoryOnly: false
            )
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }

    // MARK: - Save

    func saveTranscription(
        text: String,
        language: String,
        duration: TimeInterval,
        modelUsed: String
    ) async {
        // Get the focused app name
        let sourceApp = NSWorkspace.shared.frontmostApplication?.localizedName

        let record = TranscriptionRecord(
            text: text,
            language: language,
            duration: duration,
            modelUsed: modelUsed,
            sourceApp: sourceApp
        )

        container.mainContext.insert(record)

        do {
            try container.mainContext.save()
        } catch {
            print("Failed to save transcription: \(error)")
        }
    }

    // MARK: - Fetch

    func fetchRecords(
        searchText: String = "",
        favoritesOnly: Bool = false,
        limit: Int? = nil
    ) throws -> [TranscriptionRecord] {
        var descriptor = FetchDescriptor<TranscriptionRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        if let limit {
            descriptor.fetchLimit = limit
        }

        var predicates: [Predicate<TranscriptionRecord>] = []

        if favoritesOnly {
            predicates.append(#Predicate { $0.isFavorite })
        }

        if !searchText.isEmpty {
            predicates.append(#Predicate { record in
                record.text.localizedStandardContains(searchText)
            })
        }

        if predicates.count == 1 {
            descriptor.predicate = predicates[0]
        } else if predicates.count == 2 {
            let search = searchText
            descriptor.predicate = #Predicate { record in
                record.isFavorite && record.text.localizedStandardContains(search)
            }
        }

        return try container.mainContext.fetch(descriptor)
    }

    // MARK: - Delete

    func deleteRecord(_ record: TranscriptionRecord) throws {
        container.mainContext.delete(record)
        try container.mainContext.save()
    }

    func deleteAllRecords() throws {
        try container.mainContext.delete(model: TranscriptionRecord.self)
        try container.mainContext.save()
    }

    // MARK: - Toggle Favorite

    func toggleFavorite(_ record: TranscriptionRecord) throws {
        record.isFavorite.toggle()
        try container.mainContext.save()
    }
}
