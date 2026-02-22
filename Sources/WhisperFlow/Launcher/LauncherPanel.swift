import AppKit
import SwiftUI

final class LauncherPanel: NSObject, NSWindowDelegate {
    private var panel: NSPanel?

    override init() {
        super.init()
        setupPanel()
    }

    private func setupPanel() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.ignoresMouseEvents = false
        panel.hasShadow = true
        panel.hidesOnDeactivate = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.delegate = self

        let launcherView = LauncherView(onDismiss: { [weak self] in
            self?.hide()
        })
        let hostingView = NSHostingView(rootView: launcherView)
        panel.contentView = hostingView

        self.panel = panel
    }

    var isVisible: Bool {
        panel?.isVisible ?? false
    }

    func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    func show() {
        guard let panel = panel else { return }

        // Re-create the hosting view so state resets (fresh query, etc.)
        let launcherView = LauncherView(onDismiss: { [weak self] in
            self?.hide()
        })
        panel.contentView = NSHostingView(rootView: launcherView)

        // Center on the active screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let panelX = screenFrame.midX - panel.frame.width / 2
            let panelY = screenFrame.midY - panel.frame.height / 2 + 80 // Slightly above center (Spotlight-style)
            panel.setFrameOrigin(NSPoint(x: panelX, y: panelY))
        }

        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            panel.animator().alphaValue = 1
        }
    }

    func hide() {
        guard let panel = panel, panel.isVisible else { return }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.15
            panel.animator().alphaValue = 0
        }, completionHandler: {
            panel.orderOut(nil)
        })
    }

    // MARK: - NSWindowDelegate

    func windowDidResignKey(_ notification: Notification) {
        hide()
    }
}
