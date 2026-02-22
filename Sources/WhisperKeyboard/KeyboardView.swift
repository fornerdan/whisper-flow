import SwiftUI
import WhisperCore

enum KeyboardStatus {
    case idle
    case waitingForTranscription
    case inserting
}

struct KeyboardView: View {
    let onMicTapped: () -> Void
    let onGlobeTapped: () -> Void
    @ObservedObject var ipcClient: IPCClient

    var body: some View {
        VStack(spacing: 12) {
            // Status bar
            HStack {
                Image(systemName: "waveform")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("WhisperFlow")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Spacer()

                statusIndicator
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            // Main buttons
            HStack(spacing: 16) {
                // Globe / switch keyboard button
                Button(action: onGlobeTapped) {
                    Image(systemName: "globe")
                        .font(.system(size: 22))
                        .foregroundStyle(.primary)
                        .frame(width: 44, height: 44)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }

                Spacer()

                // Mic button (main action)
                Button(action: onMicTapped) {
                    VStack(spacing: 4) {
                        Image(systemName: "mic.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 72, height: 72)
                    .background(
                        ipcClient.status == .waitingForTranscription
                            ? Color.orange
                            : Color.accentColor
                    )
                    .clipShape(Circle())
                    .shadow(color: .accentColor.opacity(0.3), radius: 6)
                }
                .disabled(ipcClient.status == .waitingForTranscription)

                Spacer()

                // Placeholder for symmetry
                Color.clear
                    .frame(width: 44, height: 44)
            }
            .padding(.horizontal, 24)

            // Status text
            statusText
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
    }

    // MARK: - Status Indicator

    @ViewBuilder
    private var statusIndicator: some View {
        switch ipcClient.status {
        case .idle:
            EmptyView()
        case .waitingForTranscription:
            HStack(spacing: 4) {
                ProgressView()
                    .scaleEffect(0.6)
                Text("Waiting...")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        case .inserting:
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.caption2)
                    .foregroundStyle(.green)
                Text("Inserted")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
        }
    }

    // MARK: - Status Text

    @ViewBuilder
    private var statusText: some View {
        switch ipcClient.status {
        case .idle:
            Text("Tap the mic to dictate")
                .font(.caption)
                .foregroundStyle(.secondary)
        case .waitingForTranscription:
            Text("Recording in WhisperFlow... Switch back when done.")
                .font(.caption)
                .foregroundStyle(.orange)
        case .inserting:
            Text("Text inserted!")
                .font(.caption)
                .foregroundStyle(.green)
        }
    }
}
