import XCTest
@testable import WhisperFlow

final class UserPreferencesTests: XCTestCase {

    func testShowInDockDefaultsFalse() {
        let prefs = UserPreferences.shared
        // Default value is false (menu bar app, no dock icon)
        XCTAssertFalse(prefs.showInDock)
    }

    func testLauncherHotkeyDisplayString() {
        let prefs = UserPreferences.shared
        XCTAssertEqual(prefs.launcherHotkeyDisplayString, "\u{2318}\u{21E7}W")
    }

    func testHotkeyDisplayString() {
        let prefs = UserPreferences.shared
        XCTAssertEqual(prefs.hotkeyDisplayString, "\u{2318}\u{21E7}Space")
    }

    func testTranslateToEnglishDefaultsFalse() {
        let prefs = UserPreferences.shared
        XCTAssertFalse(prefs.translateToEnglish)
    }
}
