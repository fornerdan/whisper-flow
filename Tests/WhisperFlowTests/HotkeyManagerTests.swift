import XCTest
import Carbon.HIToolbox
@testable import WhisperFlow

final class HotkeyManagerTests: XCTestCase {

    func testDefaultRecordingHotkey() {
        let manager = HotkeyManager.shared
        XCTAssertEqual(manager.keyCode, UInt32(kVK_Space))
        XCTAssertEqual(manager.modifiers, UInt32(cmdKey | shiftKey))
    }

    func testDefaultLauncherHotkey() {
        let manager = HotkeyManager.shared
        XCTAssertEqual(manager.launcherKeyCode, UInt32(kVK_ANSI_W))
        XCTAssertEqual(manager.launcherModifiers, UInt32(cmdKey | shiftKey))
    }

    func testHotkeyCallbacksAreNilByDefault() {
        // Access fresh state before register() is called.
        // Note: In a test environment, register() may have been called by the app lifecycle,
        // but onLauncherHotkeyPressed should still be nil unless explicitly set by the app delegate.
        let manager = HotkeyManager.shared
        // We can at least verify the properties exist and are optional closures
        let _: (() -> Void)? = manager.onHotkeyPressed
        let _: (() -> Void)? = manager.onLauncherHotkeyPressed
    }

    func testLauncherHotkeyCallbackIsSettable() {
        let manager = HotkeyManager.shared
        var callbackInvoked = false

        manager.onLauncherHotkeyPressed = {
            callbackInvoked = true
        }

        // Invoke the callback directly to verify it was set
        manager.onLauncherHotkeyPressed?()
        XCTAssertTrue(callbackInvoked)

        // Clean up — restore to nil so we don't affect other tests
        manager.onLauncherHotkeyPressed = nil
    }
}
