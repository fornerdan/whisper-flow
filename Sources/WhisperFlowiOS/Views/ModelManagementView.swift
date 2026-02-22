import SwiftUI
import WhisperCore

struct ModelManagementView: View {
    @EnvironmentObject var modelManager: ModelManager

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(ModelCatalog.iOSRecommendedModels) { model in
                        ModelRow(model: model)
                    }
                } header: {
                    Text("Recommended for iPhone")
                } footer: {
                    Text("Smaller models are faster but less accurate. Quantized models (Q5) reduce size with minimal quality loss.")
                }

                Section("All Models") {
                    ForEach(ModelCatalog.models.filter { !ModelCatalog.isSafeForIOS($0.id) }) { model in
                        ModelRow(model: model, showWarning: true)
                    }
                }
            }
            .navigationTitle("Models")
        }
    }
}

struct ModelRow: View {
    @EnvironmentObject var modelManager: ModelManager
    let model: WhisperModel
    var showWarning: Bool = false

    private var isDownloaded: Bool { modelManager.isDownloaded(model.id) }
    private var isLoaded: Bool { modelManager.loadedModelName == model.name }
    private var isDownloading: Bool { modelManager.isDownloading }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(model.name)
                    .font(.headline)

                if isLoaded {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                }

                Spacer()

                Text(model.size)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Label(model.speed.rawValue.capitalized, systemImage: "bolt.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Label(model.quality.rawValue.capitalized, systemImage: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("RAM: \(model.ramRequired)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if showWarning {
                Label("May cause memory issues on older devices", systemImage: "exclamationmark.triangle.fill")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }

            // Action buttons
            HStack {
                if isDownloaded {
                    if isLoaded {
                        Text("Active")
                            .font(.caption)
                            .foregroundStyle(.green)
                    } else {
                        Button("Load") {
                            Task {
                                try? await modelManager.loadModel(model.id)
                            }
                        }
                        .font(.caption)
                        .buttonStyle(.bordered)
                    }

                    Spacer()

                    Button("Delete", role: .destructive) {
                        try? modelManager.deleteModel(model.id)
                    }
                    .font(.caption)
                } else {
                    if modelManager.isDownloading {
                        ProgressView(value: modelManager.downloadProgress)
                            .frame(maxWidth: .infinity)

                        Button("Cancel") {
                            modelManager.cancelDownload()
                        }
                        .font(.caption)
                    } else {
                        Button("Download") {
                            Task {
                                try? await modelManager.downloadModel(model)
                            }
                        }
                        .font(.caption)
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 4)
    }
}
