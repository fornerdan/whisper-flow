import AppKit
import SwiftUI
import WhisperCore

final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    static private(set) var shared: AppDelegate!

    private var overlayPanel: NSPanel?
    private var overlayHostingView: NSHostingView<OverlayHUD>?
    private var settingsWindow: NSWindow?
    private var historyWindow: NSWindow?
    private var launcherPanel: LauncherPanel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        Self.shared = self
        setupMainMenu()
        // Register global hotkey
        HotkeyManager.shared.register()

        // Check accessibility permission
        if !AccessibilityHelper.isTrusted {
            AccessibilityHelper.requestAccess()
        }

        // Set up overlay panel
        setupOverlayPanel()

        // Set up launcher panel
        launcherPanel = LauncherPanel()
        HotkeyManager.shared.onLauncherHotkeyPressed = { [weak self] in
            self?.launcherPanel?.toggle()
        }

        // Apply dock preference
        if UserPreferences.shared.showInDock {
            NSApp.setActivationPolicy(.regular)
        }

        // Load the selected model if available
        Task {
            await ModelManager.shared.loadSelectedModel()
        }

        // Listen for recording state changes to show/hide overlay
        NotificationCenter.default.addObserver(
            forName: .recordingStateDidChange,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.handleRecordingStateChange()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.unregister()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        launcherPanel?.toggle()
        return false
    }

    // MARK: - Main Menu

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        // App menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit WhisperFlow", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // Window menu (standard window management)
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        NSApp.mainMenu = mainMenu
        NSApp.windowsMenu = windowMenu
    }

    @objc private func openSettings() {
        showSettings()
    }

    // MARK: - Launcher

    func showLauncher() {
        launcherPanel?.show()
    }

    // MARK: - Dock Preference

    func applyDockPreference() {
        if UserPreferences.shared.showInDock {
            NSApp.setActivationPolicy(.regular)
        } else {
            // Only revert if no windows are visible
            let settingsVisible = settingsWindow?.isVisible ?? false
            let historyVisible = historyWindow?.isVisible ?? false
            if !settingsVisible && !historyVisible {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }

    // MARK: - Settings Window

    func showSettings() {
        // Set activation policy and activate IMMEDIATELY — prevents app from
        // deactivating when MenuBarExtra popup dismisses
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // Delay to let MenuBarExtra popup fully dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
            if settingsWindow == nil {
                let settingsView = SettingsView()
                    .environmentObject(TranscriptionEngine.shared)
                    .environmentObject(ModelManager.shared)

                let window = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 520, height: 420),
                    styleMask: [.titled, .closable, .miniaturizable],
                    backing: .buffered,
                    defer: false
                )
                window.title = "WhisperFlow Settings"
                window.contentView = NSHostingView(rootView: settingsView)
                window.center()
                window.delegate = self
                window.isReleasedWhenClosed = false
                self.settingsWindow = window
            }

            self.settingsWindow?.orderFrontRegardless()
            self.settingsWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - History Window

    func showHistory() {
        // Set activation policy and activate IMMEDIATELY — prevents app from
        // deactivating when MenuBarExtra popup dismisses
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // Delay to let MenuBarExtra popup fully dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [self] in
            if historyWindow == nil {
                let historyView = HistoryView()

                let window = NSWindow(
                    contentRect: NSRect(x: 0, y: 0, width: 700, height: 500),
                    styleMask: [.titled, .closable, .miniaturizable, .resizable],
                    backing: .buffered,
                    defer: false
                )
                window.title = "Transcription History"
                window.contentView = NSHostingView(rootView: historyView)
                window.center()
                window.delegate = self
                window.isReleasedWhenClosed = false
                self.historyWindow = window
            }

            self.historyWindow?.orderFrontRegardless()
            self.historyWindow?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    // MARK: - Overlay Panel

    private func setupOverlayPanel() {
        let overlayView = OverlayHUD()
        let hostingView = NSHostingView(rootView: overlayView)

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 48),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.ignoresMouseEvents = true
        panel.hasShadow = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = hostingView

        // Position at top center of screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let panelX = screenFrame.midX - panel.frame.width / 2
            let panelY = screenFrame.maxY - panel.frame.height - 20
            panel.setFrameOrigin(NSPoint(x: panelX, y: panelY))
        }

        self.overlayPanel = panel
        self.overlayHostingView = hostingView
    }

    private func handleRecordingStateChange() {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            guard UserPreferences.shared.showOverlayHUD else { return }
            guard let panel = self.overlayPanel else { return }

            let state = TranscriptionEngine.shared.state

            switch state {
            case .recording, .transcribing:
                self.overlayHostingView?.rootView = OverlayHUD()
                panel.alphaValue = 0
                panel.orderFrontRegardless()
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.2
                    panel.animator().alphaValue = 1
                }

            case .idle, .done:
                NSAnimationContext.runAnimationGroup({ context in
                    context.duration = 0.2
                    panel.animator().alphaValue = 0
                }, completionHandler: {
                    panel.orderOut(nil)
                })

            default:
                break
            }
        }
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        // Revert to accessory (no Dock icon) when all managed windows are closed,
        // unless the user has enabled "Show in Dock"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [self] in
            let settingsVisible = settingsWindow?.isVisible ?? false
            let historyVisible = historyWindow?.isVisible ?? false
            if !settingsVisible && !historyVisible && !UserPreferences.shared.showInDock {
                NSApp.setActivationPolicy(.accessory)
            }
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let recordingStateDidChange = Notification.Name("recordingStateDidChange")
}
