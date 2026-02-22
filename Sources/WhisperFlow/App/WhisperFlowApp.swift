import SwiftUI

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
    }
}
