import SwiftUI
import AVFoundation
import WhisperCore

struct OnboardingView: View {
    @EnvironmentObject var engine: iOSTranscriptionEngine
    @EnvironmentObject var modelManager: ModelManager

    @State private var currentStep = 0
    @State private var micPermissionGranted = false
    @State private var isDownloadingModel = false

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { step in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(step <= currentStep ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(height: 4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            TabView(selection: $currentStep) {
                // Step 1: Welcome
                welcomeStep
                    .tag(0)

                // Step 2: Microphone permission
                micPermissionStep
                    .tag(1)

                // Step 3: Download model
                modelDownloadStep
                    .tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)
        }
    }

    // MARK: - Step 1: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.accentColor)

            Text("Welcome to WhisperFlow")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("On-device speech-to-text, powered by whisper.cpp. Private, fast, and works offline.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button {
                currentStep = 1
            } label: {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Step 2: Mic Permission

    private var micPermissionStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "mic.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(micPermissionGranted ? .green : .accentColor)

            Text("Microphone Access")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("WhisperFlow needs microphone access to record and transcribe your speech. All processing happens on-device.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if micPermissionGranted {
                Label("Permission Granted", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
            }

            Spacer()

            VStack(spacing: 12) {
                if !micPermissionGranted {
                    Button {
                        Task {
                            micPermissionGranted = await AVCaptureDevice.requestAccess(for: .audio)
                        }
                    } label: {
                        Text("Grant Microphone Access")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                }

                Button {
                    currentStep = 2
                } label: {
                    Text(micPermissionGranted ? "Continue" : "Skip for Now")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(micPermissionGranted ? .borderedProminent : .bordered)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Step 3: Model Download

    private var modelDownloadStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.accentColor)

            Text("Download a Model")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("The Tiny model (75 MB) is recommended for iPhone. It's fast and works well for most use cases.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if modelManager.isDownloading {
                VStack(spacing: 8) {
                    ProgressView(value: modelManager.downloadProgress)
                        .padding(.horizontal, 40)
                    Text("\(Int(modelManager.downloadProgress * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if modelManager.isModelLoaded {
                Label("Model Ready", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.headline)
            }

            Spacer()

            VStack(spacing: 12) {
                if !modelManager.isModelLoaded {
                    Button {
                        Task {
                            try? await modelManager.downloadAndLoadDefault()
                        }
                    } label: {
                        Text("Download Tiny Model (75 MB)")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(modelManager.isDownloading)
                }

                Button {
                    engine.completeOnboarding()
                } label: {
                    Text(modelManager.isModelLoaded ? "Start Using WhisperFlow" : "Skip for Now")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                }
                .buttonStyle(modelManager.isModelLoaded ? .borderedProminent : .bordered)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}
