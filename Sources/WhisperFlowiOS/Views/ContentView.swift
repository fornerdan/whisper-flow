import SwiftUI
import WhisperCore

struct ContentView: View {
    @EnvironmentObject var engine: iOSTranscriptionEngine
    @EnvironmentObject var modelManager: ModelManager
    @Binding var autoStartRecording: Bool

    var body: some View {
        TabView {
            RecordingView(autoStartRecording: $autoStartRecording)
                .tabItem {
                    Label("Record", systemImage: "mic.fill")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }

            ModelManagementView()
                .tabItem {
                    Label("Models", systemImage: "arrow.down.circle.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .onChange(of: autoStartRecording) { _, shouldStart in
            if shouldStart {
                engine.launchedFromKeyboard = true
                if engine.isModelLoaded {
                    engine.startRecording()
                }
                autoStartRecording = false
            }
        }
    }
}
