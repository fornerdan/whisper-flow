import Foundation
import Combine

@MainActor
final class ModelManager: NSObject, ObservableObject {
    static let shared = ModelManager()

    @Published var downloadProgress: Double = 0
    @Published var isDownloading: Bool = false
    @Published var isModelLoaded: Bool = false
    @Published var loadedModelName: String?
    @Published var downloadedModels: Set<String> = []
    @Published var downloadError: String?

    private var activeDownloadTask: URLSessionDownloadTask?
    private var downloadContinuation: CheckedContinuation<URL, Error>?
    private lazy var downloadSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForResource = 3600 // 1 hour for large models
        return URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }()

    static var modelsDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let modelsDir = appSupport.appendingPathComponent("WhisperFlow/Models", isDirectory: true)
        try? FileManager.default.createDirectory(at: modelsDir, withIntermediateDirectories: true)
        return modelsDir
    }

    private override init() {
        super.init()
        scanDownloadedModels()
    }

    // MARK: - Model Discovery

    func scanDownloadedModels() {
        let fm = FileManager.default
        let dir = Self.modelsDirectory
        guard let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { return }

        downloadedModels = Set(
            files.compactMap { url -> String? in
                let filename = url.lastPathComponent
                return ModelCatalog.models.first { $0.filename == filename }?.id
            }
        )
    }

    func isDownloaded(_ modelId: String) -> Bool {
        downloadedModels.contains(modelId)
    }

    func modelPath(for modelId: String) -> URL? {
        guard let model = ModelCatalog.model(for: modelId) else { return nil }
        let path = Self.modelsDirectory.appendingPathComponent(model.filename)
        return FileManager.default.fileExists(atPath: path.path) ? path : nil
    }

    // MARK: - Download

    func downloadModel(_ model: WhisperModel) async throws {
        guard !isDownloading else { return }

        isDownloading = true
        downloadProgress = 0
        downloadError = nil

        defer {
            isDownloading = false
        }

        let localURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            self.downloadContinuation = continuation
            let task = downloadSession.downloadTask(with: model.downloadURL)
            self.activeDownloadTask = task
            task.resume()
        }

        // Move to models directory
        let destination = Self.modelsDirectory.appendingPathComponent(model.filename)
        let fm = FileManager.default

        if fm.fileExists(atPath: destination.path) {
            try fm.removeItem(at: destination)
        }
        try fm.moveItem(at: localURL, to: destination)

        downloadedModels.insert(model.id)
        downloadProgress = 1.0
    }

    func cancelDownload() {
        activeDownloadTask?.cancel()
        activeDownloadTask = nil
        isDownloading = false
        downloadProgress = 0
        downloadContinuation?.resume(throwing: CancellationError())
        downloadContinuation = nil
    }

    // MARK: - Delete

    func deleteModel(_ modelId: String) throws {
        guard let model = ModelCatalog.model(for: modelId) else { return }
        let path = Self.modelsDirectory.appendingPathComponent(model.filename)
        try FileManager.default.removeItem(at: path)
        downloadedModels.remove(modelId)

        // If this was the loaded model, unload it
        if loadedModelName == model.name {
            isModelLoaded = false
            loadedModelName = nil
        }
    }

    // MARK: - Load

    func loadModel(_ modelId: String) async throws {
        guard let path = modelPath(for: modelId) else {
            throw ModelError.modelNotFound(modelId)
        }

        try await TranscriptionEngine.shared.loadModel(at: path.path)
        isModelLoaded = true
        loadedModelName = ModelCatalog.model(for: modelId)?.name
        UserPreferences.shared.selectedModel = modelId
    }

    func loadSelectedModel() async {
        let selectedId = UserPreferences.shared.selectedModel
        print("[ModelManager] selectedModel preference: \(selectedId)")
        print("[ModelManager] downloaded models: \(downloadedModels)")

        // Try the selected model first, then fall back to any downloaded model
        let modelToLoad: String
        if isDownloaded(selectedId) {
            modelToLoad = selectedId
        } else if let firstAvailable = downloadedModels.first {
            print("[ModelManager] Selected model '\(selectedId)' not found, falling back to '\(firstAvailable)'")
            modelToLoad = firstAvailable
        } else {
            print("[ModelManager] No models available on disk")
            return
        }

        do {
            print("[ModelManager] Loading model '\(modelToLoad)' from: \(modelPath(for: modelToLoad)?.path ?? "nil")")
            try await loadModel(modelToLoad)
            print("[ModelManager] Model loaded successfully. isModelLoaded=\(isModelLoaded)")
        } catch {
            print("[ModelManager] Failed to load model: \(error)")
            downloadError = "Failed to load model: \(error.localizedDescription)"
        }
    }

    /// Download and load the recommended model for first launch
    func downloadAndLoadDefault() async throws {
        let model = ModelCatalog.recommendedModel
        if !isDownloaded(model.id) {
            try await downloadModel(model)
        }
        try await loadModel(model.id)
    }
}

// MARK: - URLSessionDownloadDelegate

extension ModelManager: URLSessionDownloadDelegate {
    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        // Copy to temp location before continuation resumes
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.copyItem(at: location, to: tempURL)

        Task { @MainActor in
            self.downloadContinuation?.resume(returning: tempURL)
            self.downloadContinuation = nil
            self.activeDownloadTask = nil
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let progress = totalBytesExpectedToWrite > 0
            ? Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            : 0

        Task { @MainActor in
            self.downloadProgress = progress
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let error = error else { return }
        Task { @MainActor in
            self.downloadError = error.localizedDescription
            self.downloadContinuation?.resume(throwing: error)
            self.downloadContinuation = nil
            self.activeDownloadTask = nil
        }
    }
}

enum ModelError: LocalizedError {
    case modelNotFound(String)

    var errorDescription: String? {
        switch self {
        case .modelNotFound(let id):
            return "Model '\(id)' not found on disk"
        }
    }
}
