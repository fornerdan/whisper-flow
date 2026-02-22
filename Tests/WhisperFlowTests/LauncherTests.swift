import XCTest
@testable import WhisperCore
@testable import WhisperFlow

final class LauncherTests: XCTestCase {

    // MARK: - LauncherItem

    func testLauncherItemHasUniqueId() {
        let a = LauncherItem(icon: "mic.fill", title: "A", subtitle: nil, action: .startRecording)
        let b = LauncherItem(icon: "mic.fill", title: "B", subtitle: nil, action: .startRecording)
        XCTAssertNotEqual(a.id, b.id)
    }

    func testLauncherItemProperties() {
        let item = LauncherItem(
            icon: "gear",
            title: "Open Settings",
            subtitle: "App preferences",
            action: .openSettings
        )
        XCTAssertEqual(item.icon, "gear")
        XCTAssertEqual(item.title, "Open Settings")
        XCTAssertEqual(item.subtitle, "App preferences")
        if case .openSettings = item.action {} else {
            XCTFail("Expected .openSettings action")
        }
    }

    func testLauncherItemWithNilSubtitle() {
        let item = LauncherItem(icon: "clock", title: "History", subtitle: nil, action: .openHistory)
        XCTAssertNil(item.subtitle)
    }

    // MARK: - LauncherAction

    func testLauncherActionCases() {
        // Verify all 9 cases exist and are distinguishable
        let actions: [LauncherAction] = [
            .startRecording,
            .stopRecording,
            .cancelRecording,
            .openSettings,
            .openHistory,
            .copyTranscription(TranscriptionRecord(
                text: "test", language: "en", duration: 1.0, modelUsed: "tiny"
            )),
            .toggleTranslation,
            .importFile,
            .exportHistory
        ]
        XCTAssertEqual(actions.count, 9)

        // Verify each case is distinct via pattern matching
        for (index, action) in actions.enumerated() {
            switch action {
            case .startRecording:    XCTAssertEqual(index, 0)
            case .stopRecording:     XCTAssertEqual(index, 1)
            case .cancelRecording:   XCTAssertEqual(index, 2)
            case .openSettings:      XCTAssertEqual(index, 3)
            case .openHistory:       XCTAssertEqual(index, 4)
            case .copyTranscription: XCTAssertEqual(index, 5)
            case .toggleTranslation: XCTAssertEqual(index, 6)
            case .importFile:        XCTAssertEqual(index, 7)
            case .exportHistory:     XCTAssertEqual(index, 8)
            }
        }
    }

    // MARK: - LauncherPanel

    func testLauncherPanelInitialState() {
        let panel = LauncherPanel()
        XCTAssertFalse(panel.isVisible)
    }

    func testLauncherPanelShowMakesVisible() {
        let panel = LauncherPanel()
        panel.show()
        XCTAssertTrue(panel.isVisible)
    }

    func testLauncherPanelHideMakesInvisible() {
        let panel = LauncherPanel()
        panel.show()
        XCTAssertTrue(panel.isVisible)
        panel.hide()

        // hide() uses animation; the panel becomes invisible after the animation completes.
        // The orderOut happens in the completion handler, so give it a moment.
        let expectation = expectation(description: "Panel hides after animation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(panel.isVisible)
    }

    func testLauncherPanelToggleFromHidden() {
        let panel = LauncherPanel()
        XCTAssertFalse(panel.isVisible)
        panel.toggle()
        XCTAssertTrue(panel.isVisible)
    }

    func testLauncherPanelToggleFromVisible() {
        let panel = LauncherPanel()
        panel.show()
        XCTAssertTrue(panel.isVisible)
        panel.toggle()

        let expectation = expectation(description: "Panel hides after toggle animation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        XCTAssertFalse(panel.isVisible)
    }

    func testLauncherPanelHideWhenAlreadyHidden() {
        let panel = LauncherPanel()
        XCTAssertFalse(panel.isVisible)
        panel.hide() // Should be a no-op
        XCTAssertFalse(panel.isVisible)
    }
}
