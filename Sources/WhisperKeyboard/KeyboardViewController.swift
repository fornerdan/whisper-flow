import UIKit
import SwiftUI
import WhisperCore

class KeyboardViewController: UIInputViewController {
    private var hostingController: UIHostingController<KeyboardView>?
    private var ipcClient: IPCClient!

    override func viewDidLoad() {
        super.viewDidLoad()

        ipcClient = IPCClient(textDocumentProxy: textDocumentProxy)

        let keyboardView = KeyboardView(
            onMicTapped: { [weak self] in self?.openHostApp() },
            onGlobeTapped: { [weak self] in self?.advanceToNextInputMode() },
            ipcClient: ipcClient
        )

        let hostingController = UIHostingController(rootView: keyboardView)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        hostingController.view.backgroundColor = .clear

        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)

        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hostingController.view.heightAnchor.constraint(equalToConstant: 200),
        ])

        self.hostingController = hostingController
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Fallback: Check shared container when keyboard appears
        // (in case Darwin notification was missed while keyboard was inactive)
        ipcClient.checkForPendingTranscription { [weak self] text in
            guard let self = self, let text = text else { return }
            self.textDocumentProxy.insertText(text)
            self.ipcClient.updateStatus(.idle)
        }

        // Start observing Darwin notifications for new transcriptions
        ipcClient.startObserving { [weak self] text in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.textDocumentProxy.insertText(text)
                self.ipcClient.updateStatus(.idle)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        ipcClient.stopObserving()
    }

    // MARK: - Open Host App

    /// Opens the WhisperFlow host app via URL scheme using the responder chain.
    /// This technique is used by major keyboard extensions (Gboard, SwiftKey, etc.)
    private func openHostApp() {
        guard let url = URL(string: "whisperflow://record") else { return }

        ipcClient.updateStatus(.waitingForTranscription)

        // Walk the responder chain to find an object that can open URLs
        var responder: UIResponder? = self
        let selector = sel_registerName("openURL:")
        while let r = responder {
            if r.responds(to: selector) {
                r.perform(selector, with: url)
                return
            }
            responder = r.next
        }
    }
}
