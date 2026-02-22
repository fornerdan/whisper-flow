import Foundation

/// Provides real-time transcription feedback by processing audio in chunks.
/// This is an optional enhancement over the batch transcription approach.
/// Each chunk is transcribed independently, and the final pass uses the full audio
/// for maximum accuracy.
final class StreamingTranscriber {
    private let whisperContext: WhisperContext
    private let chunkDuration: TimeInterval = 3.0 // seconds per chunk
    private let overlapDuration: TimeInterval = 0.5 // overlap between chunks
    private var accumulatedSamples: [Float] = []
    private var lastProcessedCount: Int = 0
    private var partialResults: [String] = []

    var onPartialResult: ((String) -> Void)?

    init(whisperContext: WhisperContext) {
        self.whisperContext = whisperContext
    }

    func addSamples(_ samples: [Float]) {
        accumulatedSamples.append(contentsOf: samples)

        let samplesPerChunk = Int(chunkDuration * AudioCaptureEngine.whisperSampleRate)
        let overlapSamples = Int(overlapDuration * AudioCaptureEngine.whisperSampleRate)

        // Process when we have enough new samples
        while accumulatedSamples.count - lastProcessedCount >= samplesPerChunk {
            let startIndex = max(0, lastProcessedCount - overlapSamples)
            let endIndex = min(accumulatedSamples.count, lastProcessedCount + samplesPerChunk)
            let chunk = Array(accumulatedSamples[startIndex..<endIndex])

            lastProcessedCount = endIndex

            Task {
                do {
                    let result = try await whisperContext.transcribe(samples: chunk)
                    await MainActor.run {
                        partialResults.append(result.text)
                        let combined = partialResults.joined(separator: " ")
                        onPartialResult?(combined)
                    }
                } catch {
                    // Silently skip failed chunks — final pass will cover them
                }
            }
        }
    }

    func finalize() async throws -> String {
        // Run inference on full audio for best accuracy
        let result = try await whisperContext.transcribe(samples: accumulatedSamples)
        return result.text
    }

    func reset() {
        accumulatedSamples.removeAll()
        lastProcessedCount = 0
        partialResults.removeAll()
    }
}
