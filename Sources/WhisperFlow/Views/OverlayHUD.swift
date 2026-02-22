import SwiftUI

struct OverlayHUD: View {
    @ObservedObject private var engine = TranscriptionEngine.shared

    var body: some View {
        HStack(spacing: 8) {
            statusDot
            statusText
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(.ultraThickMaterial)
                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
        )
    }

    @ViewBuilder
    private var statusDot: some View {
        switch engine.state {
        case .recording:
            Circle()
                .fill(.red)
                .frame(width: 10, height: 10)
                .overlay(
                    Circle()
                        .fill(.red.opacity(0.5))
                        .frame(width: 16, height: 16)
                        .opacity(pulseOpacity)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseOpacity)
                )
        case .transcribing:
            ProgressView()
                .controlSize(.small)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private var statusText: some View {
        switch engine.state {
        case .recording:
            Text("Recording...")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(.primary)
        case .transcribing:
            Text("Transcribing...")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(.primary)
        default:
            EmptyView()
        }
    }

    // Simple pulse animation value
    @State private var pulseOpacity: Double = 1.0
}
