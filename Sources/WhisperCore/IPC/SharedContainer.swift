import Foundation

/// IPC layer between iOS host app and keyboard extension via App Group UserDefaults + Darwin notifications.
///
/// - Host app: Records audio, transcribes, writes text via `writeTranscription(_:)`
/// - Keyboard extension: Observes Darwin notification, reads text via `readTranscription()`, inserts into text field
/// - Fallback: Keyboard checks shared container in `viewWillAppear` (in case Darwin notification was missed)
/// - TTL: Text older than 5 minutes is ignored
public final class SharedContainer {
    public static let appGroupIdentifier = "group.com.whisperflow"
    public static let darwinNotificationName = "com.whisperflow.transcription-ready"

    private static let textKey = "pendingTranscription"
    private static let timestampKey = "pendingTranscriptionTimestamp"
    private static let ttlSeconds: TimeInterval = 300 // 5 minutes

    private let userDefaults: UserDefaults?

    public static let shared = SharedContainer()

    private init() {
        self.userDefaults = UserDefaults(suiteName: Self.appGroupIdentifier)
    }

    // MARK: - Host App (Writer)

    /// Called by host app after transcription is complete.
    /// Writes text to shared container and posts Darwin notification.
    public func writeTranscription(_ text: String) {
        guard let defaults = userDefaults else {
            print("[SharedContainer] Failed to access App Group UserDefaults")
            return
        }

        defaults.set(text, forKey: Self.textKey)
        defaults.set(Date().timeIntervalSince1970, forKey: Self.timestampKey)
        defaults.synchronize()

        postDarwinNotification()
        print("[SharedContainer] Wrote transcription (\(text.count) chars)")
    }

    // MARK: - Keyboard Extension (Reader)

    /// Called by keyboard extension to read pending transcription.
    /// Returns nil if no text available or if text has expired (older than 5 minutes).
    /// Clears the container after reading.
    public func readTranscription() -> String? {
        guard let defaults = userDefaults else {
            print("[SharedContainer] Failed to access App Group UserDefaults")
            return nil
        }

        guard let text = defaults.string(forKey: Self.textKey),
              !text.isEmpty else {
            return nil
        }

        // Check TTL
        let timestamp = defaults.double(forKey: Self.timestampKey)
        guard timestamp > 0 else {
            clearTranscription()
            return nil
        }

        let age = Date().timeIntervalSince1970 - timestamp
        guard age < Self.ttlSeconds else {
            print("[SharedContainer] Transcription expired (\(Int(age))s old)")
            clearTranscription()
            return nil
        }

        // Clear after reading
        clearTranscription()
        print("[SharedContainer] Read transcription (\(text.count) chars, \(Int(age))s old)")
        return text
    }

    /// Check if there's a pending transcription without consuming it
    public var hasPendingTranscription: Bool {
        guard let defaults = userDefaults else { return false }
        guard let text = defaults.string(forKey: Self.textKey),
              !text.isEmpty else { return false }

        let timestamp = defaults.double(forKey: Self.timestampKey)
        guard timestamp > 0 else { return false }

        let age = Date().timeIntervalSince1970 - timestamp
        return age < Self.ttlSeconds
    }

    /// Clear any pending transcription
    public func clearTranscription() {
        userDefaults?.removeObject(forKey: Self.textKey)
        userDefaults?.removeObject(forKey: Self.timestampKey)
        userDefaults?.synchronize()
    }

    // MARK: - Darwin Notifications

    /// Post a Darwin notification to wake up the keyboard extension
    private func postDarwinNotification() {
        let name = Self.darwinNotificationName as CFString
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterPostNotification(center, CFNotificationName(name), nil, nil, true)
    }

    /// Register an observer for transcription-ready notifications.
    /// Call this from the keyboard extension to get notified when new text is available.
    public func observeTranscriptionReady(callback: @escaping () -> Void) {
        let name = Self.darwinNotificationName as CFString
        let center = CFNotificationCenterGetDarwinNotifyCenter()

        // Store callback in a static location since CFNotificationCallback can't capture context
        SharedContainer._notificationCallback = callback

        CFNotificationCenterAddObserver(
            center,
            Unmanaged.passUnretained(self).toOpaque(),
            { _, observer, _, _, _ in
                SharedContainer._notificationCallback?()
            },
            name,
            nil,
            .deliverImmediately
        )
    }

    /// Remove the Darwin notification observer
    public func stopObserving() {
        let name = Self.darwinNotificationName as CFString
        let center = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterRemoveObserver(
            center,
            Unmanaged.passUnretained(self).toOpaque(),
            CFNotificationName(name),
            nil
        )
        SharedContainer._notificationCallback = nil
    }

    // Static storage for Darwin notification callback (can't capture in C function pointer)
    private static var _notificationCallback: (() -> Void)?
}
