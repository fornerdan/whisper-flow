import SwiftUI
import WhisperCore

struct SettingsView: View {
    @AppStorage("language") private var language = "auto"

    var body: some View {
        NavigationStack {
            Form {
                Section("Transcription") {
                    Picker("Language", selection: $language) {
                        ForEach(supportedLanguages, id: \.code) { lang in
                            Text(lang.name).tag(lang.code)
                        }
                    }
                }

                Section("Keyboard Extension") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Setup Instructions")
                            .font(.headline)

                        Text("1. Open Settings > General > Keyboard > Keyboards")
                        Text("2. Tap \"Add New Keyboard...\"")
                        Text("3. Select \"WhisperFlow\"")
                        Text("4. Tap \"WhisperFlow\" and enable \"Allow Full Access\"")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Whisper Engine")
                        Spacer()
                        Text("whisper.cpp v1.7.4")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    private var supportedLanguages: [(code: String, name: String)] {
        [
            ("auto", "Auto-detect"),
            ("en", "English"),
            ("zh", "Chinese"),
            ("de", "German"),
            ("es", "Spanish"),
            ("ru", "Russian"),
            ("ko", "Korean"),
            ("fr", "French"),
            ("ja", "Japanese"),
            ("pt", "Portuguese"),
            ("tr", "Turkish"),
            ("pl", "Polish"),
            ("nl", "Dutch"),
            ("ar", "Arabic"),
            ("sv", "Swedish"),
            ("it", "Italian"),
            ("id", "Indonesian"),
            ("hi", "Hindi"),
            ("fi", "Finnish"),
            ("vi", "Vietnamese"),
            ("he", "Hebrew"),
            ("uk", "Ukrainian"),
            ("el", "Greek"),
            ("cs", "Czech"),
            ("ro", "Romanian"),
            ("da", "Danish"),
            ("hu", "Hungarian"),
            ("no", "Norwegian"),
            ("th", "Thai"),
        ]
    }
}
