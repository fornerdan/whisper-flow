import Foundation
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    static let toggleRecording = Self("toggleRecording", default: .init(.space, modifiers: [.command, .shift]))
}

final class HotkeyManager {
    static let shared = HotkeyManager()

    private init() {}

    func register() {
        KeyboardShortcuts.onKeyUp(for: .toggleRecording) { [weak self] in
            self?.handleHotkey()
        }
    }

    func unregister() {
        KeyboardShortcuts.disable(.toggleRecording)
    }

    @MainActor
    private func handleHotkey() {
        TranscriptionEngine.shared.toggleRecording()
    }
}
