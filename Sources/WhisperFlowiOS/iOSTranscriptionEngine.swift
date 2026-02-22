import Foundation
import Combine
import AVFoundation
import WhisperCore

public enum iOSTranscriptionState: Equatable {
    case idle
    case loading
    case recording
    case transcribing
    case done(String)
    case error(String)

    public static func == (lhs: iOSTranscriptionState, rhs: iOSTranscriptionState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading), (.recording, .recording), (.transcribing, .transcribing):
            return true
        case (.done(let a), .done(let b)):
            return a == b
        case (.error(let a), .error(let b)):
            return a == b
        default:
            return false
        }
    }
}

@MainActor
public final class iOSTranscriptionEngine: ObservableObject, ModelLoadHandler {
    public static let shared = iOSTranscriptionEngine()

    @Published public var state: iOSTranscriptionState = .idle
    @Published public var currentText: String = ""
    @Published public var audioLevel: Float = 0
    @Published public var hasCompletedOnboarding: Bool

    private let audioCaptureEngine = AudioCaptureEngine()
    private var whisperContext: WhisperContext?
    private var audioCancellable: AnyCancellable?

    /// Whether we were launched from the keyboard and should auto-return after transcription
    public var launchedFromKeyboard = false

    private init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")

        // Forward audio level from capture engine
        audioCancellable = audioCaptureEngine.$audioLevel
            .receive(on: RunLoop.main)
            .sink { [weak self] level in
                self?.audioLevel = level
            }

        // Register as model load handler
        ModelManager.shared.loadHandler = self

        // Load model on startup
        Task {
            await ModelManager.shared.loadSelectedModel()
        }
    }

    public var isModelLoaded: Bool {
        whisperContext?.isLoaded ?? false
    }

    // MARK: - ModelLoadHandler

    public func loadModel(at path: String) async throws {
        state = .loading
        do {
            whisperContext = try WhisperContext(modelPath: path)
            state = .idle
        } catch {
            state = .error("Failed to load model: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Recording

    public func startRecording() {
        guard whisperContext != nil else {
            state = .error("No model loaded. Please download a model first.")
            return
        }

        do {
            // Configure audio session for recording
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .default)
            try session.setActive(true)

            try audioCaptureEngine.startRecording()
            state = .recording
        } catch {
            state = .error("Failed to start recording: \(error.localizedDescription)")
        }
    }

    public func stopRecordingAndTranscribe() {
        let samples = audioCaptureEngine.stopRecording()

        guard !samples.isEmpty else {
            state = .idle
            return
        }

        state = .transcribing

        Task {
            do {
                let language = UserDefaults.standard.string(forKey: "language") ?? "auto"
                let lang = language == "auto" ? nil : language

                guard let context = whisperContext else {
                    state = .error("No model loaded")
                    return
                }

                let result = try await context.transcribe(
                    samples: samples,
                    language: lang
                )

                let text = result.text
                currentText = text
                state = .done(text)

                // Save to history
                await DataStore.shared.saveTranscription(
                    text: text,
                    language: result.language,
                    duration: result.duration,
                    modelUsed: ModelManager.shared.selectedModelKey
                )

                // Write to shared container for keyboard extension
                if launchedFromKeyboard {
                    SharedContainer.shared.writeTranscription(text)
                }

                // Copy to clipboard
                UIPasteboard.general.string = text

            } catch {
                state = .error("Transcription failed: \(error.localizedDescription)")
            }

            // Deactivate audio session
            try? AVAudioSession.sharedInstance().setActive(false)
        }
    }

    public func cancelRecording() {
        _ = audioCaptureEngine.stopRecording()
        state = .idle
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    public func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
}
