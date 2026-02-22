import Carbon.HIToolbox
import AppKit

/// Global hotkey manager using Carbon Event APIs.
/// Registers Cmd+Shift+Space (configurable) as a system-wide hotkey.
final class HotkeyManager {
    static let shared = HotkeyManager()

    private var hotkeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    // Hotkey ID
    private let hotkeyID = EventHotKeyID(signature: OSType(0x5746_4C57), // "WFLW"
                                          id: 1)

    // Default: Cmd+Shift+Space
    private(set) var keyCode: UInt32 = UInt32(kVK_Space)
    private(set) var modifiers: UInt32 = UInt32(cmdKey | shiftKey)

    var onHotkeyPressed: (() -> Void)?

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

            guard status == noErr, hotKeyID.id == manager.hotkeyID.id else {
                return OSStatus(eventNotHandledErr)
            }

            DispatchQueue.main.async {
                manager.onHotkeyPressed?()
            }

            return noErr
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

        // Register the hotkey
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

        // Set up the callback
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
