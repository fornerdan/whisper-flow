import AppKit

enum AccessibilityHelper {
    /// Check if the app is trusted for accessibility access
    static var isTrusted: Bool {
        AXIsProcessTrusted()
    }

    /// Request accessibility access — shows system prompt if not yet determined
    static func requestAccess() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    /// Open System Settings to the Accessibility privacy pane
    static func openSystemSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
