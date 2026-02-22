import SwiftUI

struct ModelDownloadView: View {
    @EnvironmentObject var modelManager: ModelManager
    @State private var selectedModel: WhisperModel?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Whisper Models")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Choose a model based on your needs. Smaller models are faster but less accurate. Quantized variants (Q5) use less memory with minimal quality loss.")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Model list
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(ModelCatalog.models) { model in
                        ModelRow(
                            model: model,
                            isDownloaded: modelManager.isDownloaded(model.id),
                            isLoaded: modelManager.loadedModelName == model.name,
                            isDownloading: modelManager.isDownloading && selectedModel?.id == model.id,
                            downloadProgress: modelManager.isDownloading && selectedModel?.id == model.id ? modelManager.downloadProgress : 0,
                            onDownload: { downloadModel(model) },
                            onLoad: { loadModel(model) },
                            onDelete: { deleteModel(model) }
                        )
                    }
                }
            }

            if let error = modelManager.downloadError {
                Label(error, systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding()
    }

    private func downloadModel(_ model: WhisperModel) {
        selectedModel = model
        Task {
            try? await modelManager.downloadModel(model)
        }
    }

    private func loadModel(_ model: WhisperModel) {
        Task {
            try? await modelManager.loadModel(model.id)
        }
    }

    private func deleteModel(_ model: WhisperModel) {
        try? modelManager.deleteModel(model.id)
    }
}

struct ModelRow: View {
    let model: WhisperModel
    let isDownloaded: Bool
    let isLoaded: Bool
    let isDownloading: Bool
    let downloadProgress: Double
    let onDownload: () -> Void
    let onLoad: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Model info
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(model.name)
                        .font(.headline)

                    if isLoaded {
                        Text("Active")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.green.opacity(0.2))
                            .foregroundStyle(.green)
                            .clipShape(Capsule())
                    }
                }

                HStack(spacing: 12) {
                    Label(model.size, systemImage: "arrow.down.circle")
                    Label(model.ramRequired, systemImage: "memorychip")
                    Label(model.speed.rawValue.capitalized, systemImage: "gauge.with.dots.needle.33percent")
                    Label(model.quality.rawValue.capitalized, systemImage: "star")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            // Action button
            if isDownloading {
                VStack(spacing: 4) {
                    ProgressView(value: downloadProgress)
                        .frame(width: 80)
                    Text("\(Int(downloadProgress * 100))%")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else if isDownloaded {
                HStack(spacing: 8) {
                    if !isLoaded {
                        Button("Load") { onLoad() }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                    }

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .disabled(isLoaded)
                }
            } else {
                Button("Download") { onDownload() }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isLoaded ? Color.accentColor.opacity(0.05) : Color.clear)
                .strokeBorder(isLoaded ? Color.accentColor.opacity(0.3) : Color.gray.opacity(0.2))
        )
    }
}
