import SwiftUI
import WhisperCore

@main
struct WhisperFlowiOSApp: App {
    @StateObject private var transcriptionEngine = iOSTranscriptionEngine.shared
    @StateObject private var modelManager = ModelManager.shared

    @State private var autoStartRecording = false

    var body: some Scene {
        WindowGroup {
            Group {
                if transcriptionEngine.hasCompletedOnboarding {
                    ContentView(autoStartRecording: $autoStartRecording)
                        .environmentObject(transcriptionEngine)
                        .environmentObject(modelManager)
                } else {
                    OnboardingView()
                        .environmentObject(transcriptionEngine)
                        .environmentObject(modelManager)
                }
            }
            .onOpenURL { url in
                handleDeepLink(url)
            }
        }
    }

    private func handleDeepLink(_ url: URL) {
        // Handle whisperflow://record deep link from keyboard extension
        guard url.scheme == "whisperflow" else { return }

        switch url.host {
        case "record":
            autoStartRecording = true
        default:
            break
        }
    }
}
