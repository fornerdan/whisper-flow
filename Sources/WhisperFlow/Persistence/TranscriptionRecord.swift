import Foundation

final class TranscriptionRecord: Codable, Identifiable, Equatable, Hashable {
    let id: UUID
    var text: String
    var language: String
    var duration: TimeInterval
    var modelUsed: String
    var createdAt: Date
    var isFavorite: Bool
    var sourceApp: String?

    init(
        id: UUID = UUID(),
        text: String,
        language: String,
        duration: TimeInterval,
        modelUsed: String,
        createdAt: Date = Date(),
        isFavorite: Bool = false,
        sourceApp: String? = nil
    ) {
        self.id = id
        self.text = text
        self.language = language
        self.duration = duration
        self.modelUsed = modelUsed
        self.createdAt = createdAt
        self.isFavorite = isFavorite
        self.sourceApp = sourceApp
    }

    static func == (lhs: TranscriptionRecord, rhs: TranscriptionRecord) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
