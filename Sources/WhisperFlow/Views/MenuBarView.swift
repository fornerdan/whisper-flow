import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var engine: TranscriptionEngine
    @EnvironmentObject var modelManager: ModelManager
    private var appDelegate: AppDelegate? {
        NSApp.delegate as? AppDelegate
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Status header
            statusSection

            Divider()

            // Last transcription
            if !engine.currentText.isEmpty {
                lastTranscriptionSection
                Divider()
            }

            // Quick actions
            actionsSection

            Divider()

            // Model info
            modelSection

            Divider()

            // Footer
            footerSection
        }
        .padding(12)
        .frame(width: 320)
    }

    // MARK: - Sections

    private var statusSection: some View {
        HStack(spacing: 8) {
            statusIcon
            VStack(alignment: .leading, spacing: 2) {
                Text(statusTitle)
                    .font(.headline)
                Text(statusSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if engine.state == .recording {
                audioLevelIndicator
            }
        }
    }

    private var lastTranscriptionSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Last Transcription")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(engine.currentText)
                .font(.body)
                .lineLimit(3)
                .truncationMode(.tail)

            Button("Copy to Clipboard") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(engine.currentText, forType: .string)
            }
            .buttonStyle(.link)
            .font(.caption)
        }
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                engine.toggleRecording()
            } label: {
                Label(
                    engine.state == .recording ? "Stop Recording" : "Start Recording",
                    systemImage: engine.state == .recording ? "stop.circle.fill" : "mic.circle.fill"
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .keyboardShortcut("r", modifiers: [.command])
            .disabled(!modelManager.isModelLoaded)

            if engine.state == .recording {
                Button {
                    engine.cancelRecording()
                } label: {
                    Label("Cancel Recording", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .keyboardShortcut(.escape)
            }

            Button {
                appDelegate?.showHistory()
            } label: {
                Label("Transcription History", systemImage: "clock")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .keyboardShortcut("h", modifiers: [.command])
        }
        .buttonStyle(.plain)
    }

    private var modelSection: some View {
        HStack {
            Image(systemName: "cpu")
                .foregroundStyle(.secondary)

            if modelManager.isModelLoaded {
                Text(modelManager.loadedModelName ?? "Model loaded")
                    .font(.caption)
            } else if modelManager.isDownloading {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Downloading model...")
                        .font(.caption)
                    ProgressView(value: modelManager.downloadProgress)
                        .progressViewStyle(.linear)
                }
            } else {
                Text("No model loaded")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
    }

    private var footerSection: some View {
        HStack {
            Button("Settings...") {
                appDelegate?.showSettings()
            }
            .keyboardShortcut(",", modifiers: [.command])

            Spacer()

            Button("Quit WhisperFlow") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: [.command])
        }
        .buttonStyle(.plain)
        .font(.caption)
    }

    // MARK: - Components

    @ViewBuilder
    private var statusIcon: some View {
        switch engine.state {
        case .idle:
            Image(systemName: "waveform")
                .font(.title2)
                .foregroundStyle(.secondary)
        case .recording:
            Image(systemName: "waveform.circle.fill")
                .font(.title2)
                .foregroundStyle(.red)
                .symbolEffect(.pulse)
        case .transcribing:
            ProgressView()
                .controlSize(.small)
        case .loading:
            ProgressView()
                .controlSize(.small)
        case .done:
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)
        case .error:
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title2)
                .foregroundStyle(.yellow)
        }
    }

    private var statusTitle: String {
        switch engine.state {
        case .idle: return "Ready"
        case .recording: return "Recording"
        case .transcribing: return "Transcribing..."
        case .loading: return "Loading Model..."
        case .done: return "Done"
        case .error(let msg): return "Error: \(msg)"
        }
    }

    private var statusSubtitle: String {
        switch engine.state {
        case .idle: return "Press \(UserPreferences.shared.hotkeyDisplayString) to start"
        case .recording: return "Press \(UserPreferences.shared.hotkeyDisplayString) to stop"
        case .transcribing: return "Processing audio..."
        case .loading: return "Please wait..."
        case .done: return "Text injected into focused app"
        case .error: return "Check settings or try again"
        }
    }

    private var audioLevelIndicator: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(barColor(for: i))
                    .frame(width: 3, height: barHeight(for: i))
            }
        }
        .frame(height: 20)
    }

    private func barColor(for index: Int) -> Color {
        let threshold = Float(index) / 5.0
        return engine.audioLevel > threshold ? .red : .gray.opacity(0.3)
    }

    private func barHeight(for index: Int) -> CGFloat {
        let heights: [CGFloat] = [6, 10, 14, 18, 20]
        return heights[index]
    }
}
