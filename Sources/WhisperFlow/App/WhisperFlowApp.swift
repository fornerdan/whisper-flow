import SwiftUI
import SwiftData

@main
struct WhisperFlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var transcriptionEngine = TranscriptionEngine.shared
    @StateObject private var modelManager = ModelManager.shared

    var body: some Scene {
        MenuBarExtra("WhisperFlow", systemImage: transcriptionEngine.state == .recording ? "waveform.circle.fill" : "waveform") {
            MenuBarView()
                .environmentObject(transcriptionEngine)
                .environmentObject(modelManager)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environmentObject(transcriptionEngine)
                .environmentObject(modelManager)
        }

        Window("Transcription History", id: "history") {
            HistoryView()
        }

        Window("Onboarding", id: "onboarding") {
            OnboardingView()
                .environmentObject(modelManager)
        }
    }
}
