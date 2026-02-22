import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var engine: TranscriptionEngine
    @EnvironmentObject var modelManager: ModelManager

    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            TranscriptionSettingsTab()
                .environmentObject(modelManager)
                .tabItem {
                    Label("Transcription", systemImage: "text.bubble")
                }

            HotkeySettingsTab()
                .tabItem {
                    Label("Hotkey", systemImage: "keyboard")
                }

            AboutTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 500, height: 400)
    }
}

// MARK: - General Tab

struct GeneralSettingsTab: View {
    @ObservedObject private var prefs = UserPreferences.shared

    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch WhisperFlow at login", isOn: $prefs.launchAtLogin)
            }

            Section("Interface") {
                Toggle("Show overlay HUD while recording", isOn: $prefs.showOverlayHUD)
                Toggle("Play sounds on start/stop", isOn: $prefs.playSound)
            }

            Section("Output") {
                Toggle("Auto-inject text into focused app", isOn: $prefs.autoInjectText)
                Toggle("Copy transcription to clipboard", isOn: $prefs.copyToClipboard)

                if prefs.autoInjectText && !AccessibilityHelper.isTrusted {
                    Label("Accessibility permission required for text injection", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.orange)
                        .font(.caption)

                    Button("Grant Accessibility Access") {
                        AccessibilityHelper.openSystemSettings()
                    }
                    .controlSize(.small)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Transcription Tab

struct TranscriptionSettingsTab: View {
    @EnvironmentObject var modelManager: ModelManager
    @ObservedObject private var prefs = UserPreferences.shared

    var body: some View {
        Form {
            Section("Language") {
                Picker("Transcription Language", selection: $prefs.language) {
                    ForEach(UserPreferences.supportedLanguages, id: \.code) { lang in
                        Text(lang.name).tag(lang.code)
                    }
                }
            }

            Section("Model") {
                HStack {
                    Text("Current Model:")
                    Text(modelManager.loadedModelName ?? "None")
                        .fontWeight(.medium)
                    Spacer()
                }

                ModelDownloadView()
                    .environmentObject(modelManager)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Hotkey Tab

struct HotkeySettingsTab: View {
    var body: some View {
        Form {
            Section("Global Hotkey") {
                HStack {
                    Text("Toggle Recording:")
                    Spacer()
                    Text(UserPreferences.shared.hotkeyDisplayString)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.secondary.opacity(0.15))
                        )
                        .font(.system(.body, design: .rounded, weight: .medium))
                }

                Text("Press this keyboard shortcut anywhere to start/stop recording. The transcribed text will be typed into whatever app is focused.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("To customize the hotkey, a future update will add a recorder. The default is Cmd+Shift+Space.")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - About Tab

struct AboutTab: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("WhisperFlow")
                .font(.title)
                .fontWeight(.bold)

            Text("Version 1.0.0")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("On-device voice-to-text powered by whisper.cpp")
                .font(.body)
                .foregroundStyle(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Acknowledgments")
                    .font(.headline)
                Text("whisper.cpp by Georgi Gerganov (MIT License)")
                    .font(.caption)
            }

            Spacer()
        }
        .padding()
    }
}
