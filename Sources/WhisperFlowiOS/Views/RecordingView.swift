import SwiftUI
import WhisperCore

struct RecordingView: View {
    @EnvironmentObject var engine: iOSTranscriptionEngine
    @EnvironmentObject var modelManager: ModelManager
    @Binding var autoStartRecording: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                // Status text
                statusView

                // Waveform indicator
                if case .recording = engine.state {
                    WaveformView(level: engine.audioLevel)
                        .frame(height: 60)
                        .padding(.horizontal, 40)
                }

                // Transcription result
                if case .done(let text) = engine.state {
                    transcriptionResultView(text: text)
                }

                Spacer()

                // Main action button
                actionButton

                Spacer()
                    .frame(height: 40)
            }
            .navigationTitle("WhisperFlow")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Status

    @ViewBuilder
    private var statusView: some View {
        switch engine.state {
        case .idle:
            if !modelManager.isModelLoaded {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                    Text("No model loaded")
                        .font(.headline)
                    Text("Go to the Models tab to download one.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "mic.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Tap to start recording")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }

        case .loading:
            VStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Loading model...")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

        case .recording:
            VStack(spacing: 8) {
                Image(systemName: "waveform")
                    .font(.system(size: 48))
                    .foregroundStyle(.red)
                    .symbolEffect(.variableColor.iterative)
                Text("Recording...")
                    .font(.headline)
                    .foregroundStyle(.red)
            }

        case .transcribing:
            VStack(spacing: 8) {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Transcribing...")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

        case .done:
            EmptyView()

        case .error(let message):
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.red)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }

    // MARK: - Result

    @ViewBuilder
    private func transcriptionResultView(text: String) -> some View {
        VStack(spacing: 12) {
            Text("Transcription")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView {
                Text(text)
                    .font(.body)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 200)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)

            HStack(spacing: 16) {
                Button {
                    UIPasteboard.general.string = text
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)

                if engine.launchedFromKeyboard {
                    Button {
                        SharedContainer.shared.writeTranscription(text)
                    } label: {
                        Label("Send to Keyboard", systemImage: "keyboard")
                            .font(.subheadline)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }

    // MARK: - Action Button

    @ViewBuilder
    private var actionButton: some View {
        switch engine.state {
        case .recording:
            Button {
                engine.stopRecordingAndTranscribe()
            } label: {
                ZStack {
                    Circle()
                        .fill(.red)
                        .frame(width: 80, height: 80)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white)
                        .frame(width: 28, height: 28)
                }
            }
            .shadow(color: .red.opacity(0.3), radius: 8)

        case .idle, .done, .error:
            Button {
                engine.startRecording()
            } label: {
                ZStack {
                    Circle()
                        .fill(modelManager.isModelLoaded ? Color.accentColor : Color.gray)
                        .frame(width: 80, height: 80)
                    Image(systemName: "mic.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)
                }
            }
            .disabled(!modelManager.isModelLoaded)
            .shadow(color: .accentColor.opacity(0.3), radius: 8)

        case .loading, .transcribing:
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                ProgressView()
                    .tint(.white)
            }
        }
    }
}

// MARK: - Waveform Visualization

struct WaveformView: View {
    let level: Float
    private let barCount = 20

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.red.opacity(0.7))
                    .frame(width: 4, height: barHeight(for: index))
                    .animation(
                        .easeInOut(duration: 0.15).delay(Double(index) * 0.01),
                        value: level
                    )
            }
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        let normalized = CGFloat(min(level * 10, 1.0))
        let centerIndex = CGFloat(barCount) / 2.0
        let distance = abs(CGFloat(index) - centerIndex) / centerIndex
        let height = normalized * (1.0 - distance * 0.5) * 50 + 4
        return max(4, height)
    }
}
