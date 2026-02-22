import Foundation
import Combine
import AppKit
import WhisperCore

enum TranscriptionState: Equatable {
    case idle
    case loading
    case recording
    case transcribing
    case done(String)
    case error(String)

    static func == (lhs: TranscriptionState, rhs: TranscriptionState) -> Bool {
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
final class TranscriptionEngine: ObservableObject, ModelLoadHandler {
    static let shared = TranscriptionEngine()

    @Published var state: TranscriptionState = .idle {
        didSet {
            NotificationCenter.default.post(name: .recordingStateDidChange, object: nil)
        }
    }
    @Published var currentText: String = ""
    @Published var audioLevel: Float = 0

    private let audioCaptureEngine = AudioCaptureEngine()
    var whisperContext: WhisperContext?
    private var audioCancellable: AnyCancellable?

    private init() {
        // Forward audio level from capture engine
        audioCancellable = audioCaptureEngine.$audioLevel
            .receive(on: RunLoop.main)
            .sink { [weak self] level in
                self?.audioLevel = level
            }

        // Register as model load handler
        ModelManager.shared.loadHandler = self
    }

    var isModelLoaded: Bool {
        whisperContext?.isLoaded ?? false
    }

    // MARK: - ModelLoadHandler

    func loadModel(at path: String) async throws {
        state = .loading
        do {
            whisperContext = try WhisperContext(modelPath: path)
            state = .idle
        } catch {
            state = .error("Failed to load model: \(error.localizedDescription)")
            throw error
        }
    }

    func toggleRecording() {
        switch state {
        case .recording:
            stopRecordingAndTranscribe()
        case .idle, .done, .error:
            startRecording()
        default:
            break
        }
    }

    func startRecording() {
        guard whisperContext != nil else {
            state = .error("No model loaded. Please download a model first.")
            return
        }

        do {
            if UserPreferences.shared.playSound {
                NSSound(named: "Tink")?.play()
            }
            try audioCaptureEngine.startRecording()
            state = .recording
        } catch {
            state = .error("Failed to start recording: \(error.localizedDescription)")
        }
    }

    func stopRecordingAndTranscribe() {
        let samples = audioCaptureEngine.stopRecording()

        guard !samples.isEmpty else {
            state = .idle
            return
        }

        if UserPreferences.shared.playSound {
            NSSound(named: "Pop")?.play()
        }

        state = .transcribing

        Task {
            do {
                let prefs = UserPreferences.shared
                let language = prefs.language == "auto" ? nil : prefs.language

                guard let context = whisperContext else {
                    state = .error("No model loaded")
                    return
                }

                let result = try await context.transcribe(
                    samples: samples,
                    language: language,
                    translate: prefs.translateToEnglish
                )

                let text = result.text
                currentText = text
                state = .done(text)

                // Get source app name from NSWorkspace (macOS-specific)
                let sourceApp = NSWorkspace.shared.frontmostApplication?.localizedName

                // Save to history
                await DataStore.shared.saveTranscription(
                    text: text,
                    language: result.language,
                    duration: result.duration,
                    modelUsed: ModelManager.shared.selectedModelKey,
                    sourceApp: sourceApp
                )

                // Copy to clipboard if enabled
                if prefs.copyToClipboard {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(text, forType: .string)
                }

                // Inject text if enabled
                if prefs.autoInjectText && !text.isEmpty {
                    try await Task.sleep(for: .milliseconds(100))
                    TextInjector.type(text)
                }

            } catch {
                state = .error("Transcription failed: \(error.localizedDescription)")
            }
        }
    }

    func cancelRecording() {
        _ = audioCaptureEngine.stopRecording()
        state = .idle
    }
}
