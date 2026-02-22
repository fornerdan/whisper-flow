import Foundation

public struct WhisperModel: Identifiable, Codable, Equatable {
    public let id: String          // e.g., "base", "small", "medium"
    public let name: String        // e.g., "Base", "Small", "Medium"
    public let size: String        // e.g., "142 MB"
    public let sizeBytes: Int64
    public let ramRequired: String // e.g., "~388 MB"
    public let speed: ModelSpeed
    public let quality: ModelQuality
    public let downloadURL: URL
    public let filename: String    // e.g., "ggml-base.bin"

    public init(
        id: String, name: String, size: String, sizeBytes: Int64,
        ramRequired: String, speed: ModelSpeed, quality: ModelQuality,
        downloadURL: URL, filename: String
    ) {
        self.id = id
        self.name = name
        self.size = size
        self.sizeBytes = sizeBytes
        self.ramRequired = ramRequired
        self.speed = speed
        self.quality = quality
        self.downloadURL = downloadURL
        self.filename = filename
    }

    public enum ModelSpeed: String, Codable, Comparable {
        case fastest, fast, medium, slow, slowest

        public static func < (lhs: ModelSpeed, rhs: ModelSpeed) -> Bool {
            let order: [ModelSpeed] = [.fastest, .fast, .medium, .slow, .slowest]
            return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
        }
    }

    public enum ModelQuality: String, Codable, Comparable {
        case basic, good, great, excellent, best

        public static func < (lhs: ModelQuality, rhs: ModelQuality) -> Bool {
            let order: [ModelQuality] = [.basic, .good, .great, .excellent, .best]
            return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
        }
    }
}

public enum ModelCatalog {
    private static let baseURL = "https://huggingface.co/ggerganov/whisper.cpp/resolve/main"

    public static let models: [WhisperModel] = [
        WhisperModel(
            id: "tiny",
            name: "Tiny",
            size: "75 MB",
            sizeBytes: 75_000_000,
            ramRequired: "~273 MB",
            speed: .fastest,
            quality: .basic,
            downloadURL: URL(string: "\(baseURL)/ggml-tiny.bin")!,
            filename: "ggml-tiny.bin"
        ),
        WhisperModel(
            id: "base",
            name: "Base",
            size: "142 MB",
            sizeBytes: 142_000_000,
            ramRequired: "~388 MB",
            speed: .fast,
            quality: .good,
            downloadURL: URL(string: "\(baseURL)/ggml-base.bin")!,
            filename: "ggml-base.bin"
        ),
        WhisperModel(
            id: "small",
            name: "Small",
            size: "466 MB",
            sizeBytes: 466_000_000,
            ramRequired: "~852 MB",
            speed: .medium,
            quality: .great,
            downloadURL: URL(string: "\(baseURL)/ggml-small.bin")!,
            filename: "ggml-small.bin"
        ),
        WhisperModel(
            id: "medium",
            name: "Medium",
            size: "1.5 GB",
            sizeBytes: 1_500_000_000,
            ramRequired: "~2.1 GB",
            speed: .slow,
            quality: .excellent,
            downloadURL: URL(string: "\(baseURL)/ggml-medium.bin")!,
            filename: "ggml-medium.bin"
        ),
        WhisperModel(
            id: "large-v3",
            name: "Large v3",
            size: "2.9 GB",
            sizeBytes: 2_900_000_000,
            ramRequired: "~3.9 GB",
            speed: .slowest,
            quality: .best,
            downloadURL: URL(string: "\(baseURL)/ggml-large-v3.bin")!,
            filename: "ggml-large-v3.bin"
        ),
        // Quantized variants
        WhisperModel(
            id: "tiny-q5_0",
            name: "Tiny (Q5_0)",
            size: "32 MB",
            sizeBytes: 32_000_000,
            ramRequired: "~150 MB",
            speed: .fastest,
            quality: .basic,
            downloadURL: URL(string: "\(baseURL)/ggml-tiny-q5_0.bin")!,
            filename: "ggml-tiny-q5_0.bin"
        ),
        WhisperModel(
            id: "base-q5_0",
            name: "Base (Q5_0)",
            size: "57 MB",
            sizeBytes: 57_000_000,
            ramRequired: "~200 MB",
            speed: .fast,
            quality: .good,
            downloadURL: URL(string: "\(baseURL)/ggml-base-q5_0.bin")!,
            filename: "ggml-base-q5_0.bin"
        ),
        WhisperModel(
            id: "small-q5_1",
            name: "Small (Q5_1)",
            size: "190 MB",
            sizeBytes: 190_000_000,
            ramRequired: "~500 MB",
            speed: .medium,
            quality: .great,
            downloadURL: URL(string: "\(baseURL)/ggml-small-q5_1.bin")!,
            filename: "ggml-small-q5_1.bin"
        ),
        WhisperModel(
            id: "medium-q5_0",
            name: "Medium (Q5_0)",
            size: "539 MB",
            sizeBytes: 539_000_000,
            ramRequired: "~1.0 GB",
            speed: .slow,
            quality: .excellent,
            downloadURL: URL(string: "\(baseURL)/ggml-medium-q5_0.bin")!,
            filename: "ggml-medium-q5_0.bin"
        ),
        WhisperModel(
            id: "large-v3-q5_0",
            name: "Large v3 (Q5_0)",
            size: "1.1 GB",
            sizeBytes: 1_100_000_000,
            ramRequired: "~1.8 GB",
            speed: .slowest,
            quality: .best,
            downloadURL: URL(string: "\(baseURL)/ggml-large-v3-q5_0.bin")!,
            filename: "ggml-large-v3-q5_0.bin"
        )
    ]

    public static func model(for id: String) -> WhisperModel? {
        models.first { $0.id == id }
    }

    public static var recommendedModel: WhisperModel {
        #if os(iOS)
        model(for: "tiny")!
        #else
        model(for: "base")!
        #endif
    }

    /// Models recommended for iOS (small enough to fit in iPhone RAM)
    public static var iOSRecommendedModels: [WhisperModel] {
        models.filter { $0.sizeBytes <= 500_000_000 } // Up to ~500MB
    }

    /// Whether a model is safe for iOS use (won't exhaust memory)
    public static func isSafeForIOS(_ modelId: String) -> Bool {
        guard let model = model(for: modelId) else { return false }
        return model.sizeBytes <= 500_000_000
    }
}
