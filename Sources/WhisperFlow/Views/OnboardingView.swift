import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var modelManager: ModelManager
    @State private var currentStep = 0
    @Environment(\.dismiss) private var dismiss

    private let totalSteps = 5

    var body: some View {
        VStack(spacing: 0) {
            // Progress bar
            ProgressView(value: Double(currentStep), total: Double(totalSteps - 1))
                .padding(.horizontal)
                .padding(.top, 12)

            // Content
            TabView(selection: $currentStep) {
                WelcomeStep(onContinue: nextStep)
                    .tag(0)

                MicrophoneStep(onContinue: nextStep)
                    .tag(1)

                AccessibilityStep(onContinue: nextStep)
                    .tag(2)

                ModelDownloadStep(onContinue: nextStep)
                    .environmentObject(modelManager)
                    .tag(3)

                CompletionStep(onFinish: completeOnboarding)
                    .tag(4)
            }
            .tabViewStyle(.automatic)
        }
        .frame(width: 520, height: 420)
        .interactiveDismissDisabled()
    }

    private func nextStep() {
        withAnimation {
            currentStep = min(currentStep + 1, totalSteps - 1)
        }
    }

    private func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
        dismiss()
    }
}

// MARK: - Step 1: Welcome

struct WelcomeStep: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            Text("Welcome to WhisperFlow")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("On-device voice-to-text that works everywhere.\nPress a hotkey, speak, and transcribed text appears in any app.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            VStack(alignment: .leading, spacing: 8) {
                FeatureRow(icon: "lock.shield", text: "100% private - all processing on-device")
                FeatureRow(icon: "bolt", text: "Fast transcription with whisper.cpp")
                FeatureRow(icon: "globe", text: "98+ languages supported")
                FeatureRow(icon: "keyboard", text: "Global hotkey works in any app")
            }
            .padding(.horizontal, 60)

            Spacer()

            Button("Get Started") { onContinue() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

            Spacer().frame(height: 20)
        }
    }
}

// MARK: - Step 2: Microphone

struct MicrophoneStep: View {
    let onContinue: () -> Void
    @State private var permissionStatus: AudioPermissionStatus = AudioPermissionHelper.status

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "mic.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("Microphone Access")
                .font(.title)
                .fontWeight(.bold)

            Text("WhisperFlow needs access to your microphone to record audio for transcription. Audio is never sent to any server.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            switch permissionStatus {
            case .granted:
                Label("Microphone access granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)

            case .denied:
                Label("Microphone access denied", systemImage: "xmark.circle.fill")
                    .foregroundStyle(.red)

                Button("Open System Settings") {
                    AudioPermissionHelper.openSystemPreferences()
                }
                .controlSize(.small)

            case .notDetermined:
                Button("Allow Microphone Access") {
                    Task {
                        let granted = await AudioPermissionHelper.requestAccess()
                        permissionStatus = granted ? .granted : .denied
                    }
                }
                .buttonStyle(.borderedProminent)
            }

            Spacer()

            Button("Continue") { onContinue() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(permissionStatus != .granted)

            if permissionStatus != .granted {
                Button("Skip for now") { onContinue() }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer().frame(height: 20)
        }
    }
}

// MARK: - Step 3: Accessibility

struct AccessibilityStep: View {
    let onContinue: () -> Void
    @State private var isTrusted = AccessibilityHelper.isTrusted

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "hand.raised.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("Accessibility Access")
                .font(.title)
                .fontWeight(.bold)

            Text("WhisperFlow needs Accessibility permission to type transcribed text into other apps. This is required for the core functionality.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if isTrusted {
                Label("Accessibility access granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else {
                Button("Grant Accessibility Access") {
                    AccessibilityHelper.requestAccess()
                    // Check again after a delay (user needs to toggle in System Settings)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isTrusted = AccessibilityHelper.isTrusted
                    }
                }
                .buttonStyle(.borderedProminent)

                Text("After clicking, you may need to toggle WhisperFlow ON in System Settings > Privacy & Security > Accessibility")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Button("Open System Settings") {
                    AccessibilityHelper.openSystemSettings()
                }
                .controlSize(.small)

                Button("Refresh Status") {
                    isTrusted = AccessibilityHelper.isTrusted
                }
                .controlSize(.small)
            }

            Spacer()

            Button("Continue") { onContinue() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

            Spacer().frame(height: 20)
        }
    }
}

// MARK: - Step 4: Model Download

struct ModelDownloadStep: View {
    let onContinue: () -> Void
    @EnvironmentObject var modelManager: ModelManager

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("Download Speech Model")
                .font(.title)
                .fontWeight(.bold)

            Text("WhisperFlow needs a speech recognition model. The Base model (142 MB) offers a good balance of speed and accuracy.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            if modelManager.isModelLoaded {
                Label("Model ready", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            } else if modelManager.isDownloading {
                VStack(spacing: 8) {
                    ProgressView(value: modelManager.downloadProgress)
                        .frame(width: 200)
                    Text("Downloading... \(Int(modelManager.downloadProgress * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Button("Download Base Model (142 MB)") {
                    Task {
                        try? await modelManager.downloadAndLoadDefault()
                    }
                }
                .buttonStyle(.borderedProminent)
            }

            if let error = modelManager.downloadError {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Spacer()

            Button("Continue") { onContinue() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!modelManager.isModelLoaded)

            if !modelManager.isModelLoaded && !modelManager.isDownloading {
                Button("Skip for now") { onContinue() }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer().frame(height: 20)
        }
    }
}

// MARK: - Step 5: Done

struct CompletionStep: View {
    let onFinish: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)

            Text("You're All Set!")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("WhisperFlow is ready. It lives in your menu bar and is always available.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            VStack(alignment: .leading, spacing: 12) {
                HowToRow(step: "1", text: "Press \(UserPreferences.shared.hotkeyDisplayString) to start recording")
                HowToRow(step: "2", text: "Speak naturally")
                HowToRow(step: "3", text: "Press \(UserPreferences.shared.hotkeyDisplayString) again to stop")
                HowToRow(step: "4", text: "Transcribed text appears in your focused app")
            }
            .padding(.horizontal, 60)

            Spacer()

            Button("Start Using WhisperFlow") { onFinish() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

            Spacer().frame(height: 20)
        }
    }
}

// MARK: - Components

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 24)
                .foregroundStyle(.blue)
            Text(text)
                .font(.callout)
        }
    }
}

struct HowToRow: View {
    let step: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Text(step)
                .font(.caption)
                .fontWeight(.bold)
                .frame(width: 24, height: 24)
                .background(Circle().fill(.blue))
                .foregroundStyle(.white)
            Text(text)
                .font(.callout)
        }
    }
}
