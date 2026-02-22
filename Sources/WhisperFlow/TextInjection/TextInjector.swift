import AppKit
import Carbon.HIToolbox

/// Injects text into the currently focused application.
/// Uses clipboard paste for long text (fast) and CGEvent keystrokes for short text (natural).
enum TextInjector {
    /// Threshold for switching from keystroke simulation to clipboard paste
    private static let pasteThreshold = 50

    /// Type text into the focused application
    static func type(_ text: String) {
        guard !text.isEmpty else { return }
        guard AccessibilityHelper.isTrusted else {
            AccessibilityHelper.requestAccess()
            return
        }

        if text.count > pasteThreshold {
            pasteText(text)
        } else {
            simulateKeystrokes(text)
        }
    }

    /// Paste text via clipboard (fast, for longer text)
    private static func pasteText(_ text: String) {
        let pasteboard = NSPasteboard.general

        // Save current clipboard contents
        let savedItems = pasteboard.pasteboardItems?.compactMap { item -> (NSPasteboard.PasteboardType, Data)? in
            guard let types = item.types.first,
                  let data = item.data(forType: types) else { return nil }
            return (types, data)
        } ?? []

        // Set our text
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Small delay to let pasteboard update
        usleep(50_000) // 50ms

        // Simulate Cmd+V
        let source = CGEventSource(stateID: .combinedSessionState)

        let vKeyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
        vKeyDown?.flags = .maskCommand
        vKeyDown?.post(tap: .cghidEventTap)

        let vKeyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        vKeyUp?.flags = .maskCommand
        vKeyUp?.post(tap: .cghidEventTap)

        // Restore original clipboard after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !savedItems.isEmpty {
                pasteboard.clearContents()
                for (type, data) in savedItems {
                    pasteboard.setData(data, forType: type)
                }
            }
        }
    }

    /// Simulate individual keystrokes (natural, for shorter text)
    private static func simulateKeystrokes(_ text: String) {
        let source = CGEventSource(stateID: .combinedSessionState)

        for character in text {
            let string = String(character)
            let utf16 = Array(string.utf16)

            let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true)
            keyDown?.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
            keyDown?.post(tap: .cghidEventTap)

            let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
            keyUp?.post(tap: .cghidEventTap)

            // Small delay to prevent dropped keys
            usleep(1_500) // 1.5ms
        }
    }
}
