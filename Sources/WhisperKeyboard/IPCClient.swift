import Foundation
import UIKit
import WhisperCore

/// Keyboard extension IPC client — reads transcriptions from the shared container
/// and observes Darwin notifications for real-time updates.
final class IPCClient: ObservableObject {
    @Published var status: KeyboardStatus = .idle

    private weak var textDocumentProxy: UITextDocumentProxy?
    private let sharedContainer = SharedContainer.shared

    init(textDocumentProxy: UITextDocumentProxy) {
        self.textDocumentProxy = textDocumentProxy
    }

    /// Update the keyboard status (called from KeyboardViewController)
    func updateStatus(_ newStatus: KeyboardStatus) {
        DispatchQueue.main.async {
            self.status = newStatus
        }
    }

    /// Check for pending transcription in the shared container (fallback for missed notifications)
    func checkForPendingTranscription(completion: @escaping (String?) -> Void) {
        if let text = sharedContainer.readTranscription() {
            completion(text)
        } else {
            completion(nil)
        }
    }

    /// Start observing Darwin notifications for new transcriptions
    func startObserving(onTranscriptionReady: @escaping (String) -> Void) {
        sharedContainer.observeTranscriptionReady { [weak self] in
            guard let self = self else { return }
            // Small delay to ensure the write has completed
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let text = self.sharedContainer.readTranscription() {
                    self.updateStatus(.inserting)
                    onTranscriptionReady(text)

                    // Reset to idle after a brief moment
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        self.updateStatus(.idle)
                    }
                }
            }
        }
    }

    /// Stop observing Darwin notifications
    func stopObserving() {
        sharedContainer.stopObserving()
    }
}
