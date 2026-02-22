import Foundation
import WhisperBridge

struct TranscriptionSegment {
    let text: String
    let startTime: TimeInterval
    let endTime: TimeInterval
}

struct TranscriptionResult {
    let text: String
    let segments: [TranscriptionSegment]
    let language: String
    let duration: TimeInterval
}

final class WhisperContext {
    private var context: OpaquePointer?
    private let inferenceQueue = DispatchQueue(label: "com.whisperflow.inference", qos: .userInitiated)

    var isLoaded: Bool { context != nil }

    init(modelPath: String) throws {
        print("[WhisperContext] Loading model from: \(modelPath)")
        print("[WhisperContext] File exists: \(FileManager.default.fileExists(atPath: modelPath))")

        var params = whisper_context_default_params()
        params.use_gpu = true

        guard let ctx = whisper_init_from_file_with_params(modelPath, params) else {
            print("[WhisperContext] whisper_init_from_file_with_params returned nil!")
            throw WhisperError.modelLoadFailed(modelPath)
        }
        print("[WhisperContext] Model loaded successfully, context: \(ctx)")
        self.context = ctx
    }

    deinit {
        if let ctx = context {
            whisper_free(ctx)
        }
    }

    func transcribe(
        samples: [Float],
        language: String? = nil,
        translate: Bool = false
    ) async throws -> TranscriptionResult {
        guard let ctx = context else {
            throw WhisperError.contextNotInitialized
        }

        return try await withCheckedThrowingContinuation { continuation in
            inferenceQueue.async {
                do {
                    let result = try self.runInference(
                        ctx: ctx,
                        samples: samples,
                        language: language,
                        translate: translate
                    )
                    continuation.resume(returning: result)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    private func runInference(
        ctx: OpaquePointer,
        samples: [Float],
        language: String?,
        translate: Bool
    ) throws -> TranscriptionResult {
        var params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY)

        // Configure parameters
        params.print_realtime = false
        params.print_progress = false
        params.print_timestamps = false
        params.print_special = false
        params.n_threads = Int32(max(1, ProcessInfo.processInfo.activeProcessorCount - 2))
        params.translate = translate
        params.no_timestamps = false
        params.single_segment = false
        params.token_timestamps = true

        // Set language
        let languageCString: UnsafePointer<CChar>?
        var languageData: Data?
        if let lang = language, lang != "auto" {
            languageData = lang.data(using: .utf8)
            languageCString = languageData?.withUnsafeBytes { $0.baseAddress?.assumingMemoryBound(to: CChar.self) }
        } else {
            languageCString = nil
        }
        // Language param requires careful handling - use a stable pointer
        let langPtr: UnsafeMutablePointer<CChar>?
        if let lang = language, lang != "auto" {
            langPtr = strdup(lang)
            params.language = UnsafePointer(langPtr)
        } else {
            langPtr = nil
            params.language = nil
        }
        defer { langPtr.map { free($0) } }

        // Run whisper inference
        let result = samples.withUnsafeBufferPointer { samplesPtr in
            whisper_full(ctx, params, samplesPtr.baseAddress, Int32(samples.count))
        }

        guard result == 0 else {
            throw WhisperError.inferenceFailed(code: Int(result))
        }

        // Extract segments
        let segmentCount = whisper_full_n_segments(ctx)
        var segments: [TranscriptionSegment] = []
        var fullText = ""

        for i in 0..<segmentCount {
            if let textPtr = whisper_full_get_segment_text(ctx, i) {
                let text = String(cString: textPtr)
                let startTime = TimeInterval(whisper_full_get_segment_t0(ctx, i)) / 100.0
                let endTime = TimeInterval(whisper_full_get_segment_t1(ctx, i)) / 100.0

                segments.append(TranscriptionSegment(
                    text: text,
                    startTime: startTime,
                    endTime: endTime
                ))
                fullText += text
            }
        }

        // Detect language
        let detectedLanguage: String
        if let lang = language, lang != "auto" {
            detectedLanguage = lang
        } else {
            let langId = whisper_full_lang_id(ctx)
            if let langStr = whisper_lang_str(langId) {
                detectedLanguage = String(cString: langStr)
            } else {
                detectedLanguage = "en"
            }
        }

        let duration = Double(samples.count) / AudioCaptureEngine.whisperSampleRate

        return TranscriptionResult(
            text: fullText.trimmingCharacters(in: .whitespacesAndNewlines),
            segments: segments,
            language: detectedLanguage,
            duration: duration
        )
    }

    static func systemInfo() -> String {
        if let info = whisper_bridge_system_info() {
            return String(cString: info)
        }
        return "Unknown"
    }
}

enum WhisperError: LocalizedError {
    case modelLoadFailed(String)
    case contextNotInitialized
    case inferenceFailed(code: Int)

    var errorDescription: String? {
        switch self {
        case .modelLoadFailed(let path):
            return "Failed to load whisper model at: \(path)"
        case .contextNotInitialized:
            return "Whisper context is not initialized"
        case .inferenceFailed(let code):
            return "Whisper inference failed with code: \(code)"
        }
    }
}
