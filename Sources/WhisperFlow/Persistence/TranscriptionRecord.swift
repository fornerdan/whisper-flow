import Foundation
import SwiftData

@Model
final class TranscriptionRecord {
    var text: String
    var language: String
    var duration: TimeInterval
    var modelUsed: String
    var createdAt: Date
    var isFavorite: Bool
    var sourceApp: String?

    init(
        text: String,
        language: String,
        duration: TimeInterval,
        modelUsed: String,
        createdAt: Date = Date(),
        isFavorite: Bool = false,
        sourceApp: String? = nil
    ) {
        self.text = text
        self.language = language
        self.duration = duration
        self.modelUsed = modelUsed
        self.createdAt = createdAt
        self.isFavorite = isFavorite
        self.sourceApp = sourceApp
    }
}
