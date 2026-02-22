import Carbon.HIToolbox
import AppKit

/// Global hotkey manager using Carbon Event APIs.
/// Registers Cmd+Shift+Space (configurable) as a system-wide hotkey.
final class HotkeyManager {
    static let shared = HotkeyManager()

    private var hotkeyRef: EventHotKeyRef?
    private var launcherHotkeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    // Hotkey IDs (same signature, different id)
    private let hotkeyID = EventHotKeyID(signature: OSType(0x5746_4C57), // "WFLW"
                                          id: 1)
    private let launcherHotkeyID = EventHotKeyID(signature: OSType(0x5746_4C57),
                                                  id: 2)

    // Default: Cmd+Shift+Space for recording
    private(set) var keyCode: UInt32 = UInt32(kVK_Space)
    private(set) var modifiers: UInt32 = UInt32(cmdKey | shiftKey)

    // Default: Cmd+Shift+W for launcher
    private(set) var launcherKeyCode: UInt32 = UInt32(kVK_ANSI_W)
    private(set) var launcherModifiers: UInt32 = UInt32(cmdKey | shiftKey)

    var onHotkeyPressed: (() -> Void)?
    var onLauncherHotkeyPressed: (() -> Void)?

    private init() {}

    func register() {
        // Install Carbon event handler for hot key events
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let handler: EventHandlerUPP = { _, event, userData -> OSStatus in
            guard let userData = userData else { return OSStatus(eventNotHandledErr) }
            let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()

            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )

            guard status == noErr else {
                return OSStatus(eventNotHandledErr)
            }

            if hotKeyID.id == manager.hotkeyID.id {
                DispatchQueue.main.async {
                    manager.onHotkeyPressed?()
                }
                return noErr
            } else if hotKeyID.id == manager.launcherHotkeyID.id {
                DispatchQueue.main.async {
                    manager.onLauncherHotkeyPressed?()
                }
                return noErr
            }

            return OSStatus(eventNotHandledErr)
        }

        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            handler,
            1,
            &eventType,
            selfPtr,
            &eventHandler
        )

        // Register the recording hotkey
        var ref: EventHotKeyRef?
        var keyID = hotkeyID
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            keyID,
            GetApplicationEventTarget(),
            0,
            &ref
        )

        if status == noErr {
            hotkeyRef = ref
        }

        // Register the launcher hotkey
        var launcherRef: EventHotKeyRef?
        var launcherKeyIDVar = launcherHotkeyID
        let launcherStatus = RegisterEventHotKey(
            launcherKeyCode,
            launcherModifiers,
            launcherKeyIDVar,
            GetApplicationEventTarget(),
            0,
            &launcherRef
        )

        if launcherStatus == noErr {
            launcherHotkeyRef = launcherRef
        }

        // Set up the recording callback
        onHotkeyPressed = {
            Task { @MainActor in
                TranscriptionEngine.shared.toggleRecording()
            }
        }
    }

    func unregister() {
        if let ref = hotkeyRef {
            UnregisterEventHotKey(ref)
            hotkeyRef = nil
        }
        if let ref = launcherHotkeyRef {
            UnregisterEventHotKey(ref)
            launcherHotkeyRef = nil
        }
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }

    /// Update the hotkey binding
    func updateHotkey(keyCode: UInt32, modifiers: UInt32) {
        unregister()
        self.keyCode = keyCode
        self.modifiers = modifiers
        register()
    }
}
