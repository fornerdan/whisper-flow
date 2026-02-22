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
    public var sourceFile: String?
    public var title: String?

    /// Returns `title` if set, otherwise the first line of `text` truncated to 100 characters.
    public var displayTitle: String {
        if let title, !title.isEmpty {
            return title
        }
        let firstLine = text.components(separatedBy: .newlines).first ?? text
        if firstLine.count > 100 {
            return String(firstLine.prefix(100)) + "…"
        }
        return String(firstLine)
    }

    public init(
        id: UUID = UUID(),
        text: String,
        language: String,
        duration: TimeInterval,
        modelUsed: String,
        createdAt: Date = Date(),
        isFavorite: Bool = false,
        sourceApp: String? = nil,
        sourceFile: String? = nil,
        title: String? = nil
    ) {
        self.id = id
        self.text = text
        self.language = language
        self.duration = duration
        self.modelUsed = modelUsed
        self.createdAt = createdAt
        self.isFavorite = isFavorite
        self.sourceApp = sourceApp
        self.sourceFile = sourceFile
        self.title = title
    }

    public static func == (lhs: TranscriptionRecord, rhs: TranscriptionRecord) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
