import Foundation

public final class TranscriptionRecord: Codable, Identifiable, Equatable, Hashable {
    public let id: UUID
    public var text: String
    public var language: String
    public var duration: TimeInterval
    public var modelUsed: String
    public var createdAt: Date
    public var isFavorite: Bool
    public var sourceApp: String?

    public init(
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

    public static func == (lhs: TranscriptionRecord, rhs: TranscriptionRecord) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
