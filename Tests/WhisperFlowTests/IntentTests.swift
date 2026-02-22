import XCTest
import AppIntents
@testable import WhisperFlow

final class IntentTests: XCTestCase {

    // MARK: - ToggleRecordingIntent

    func testToggleRecordingIntentTitle() {
        XCTAssertEqual(
            String(localized: ToggleRecordingIntent.title),
            "Toggle Recording"
        )
    }

    func testToggleRecordingIntentDescription() {
        let description = ToggleRecordingIntent.description
        XCTAssertNotNil(description)
    }

    func testToggleRecordingIntentOpensApp() {
        XCTAssertTrue(ToggleRecordingIntent.openAppWhenRun)
    }

    // MARK: - GetLastTranscriptionIntent

    func testGetLastTranscriptionIntentTitle() {
        XCTAssertEqual(
            String(localized: GetLastTranscriptionIntent.title),
            "Get Last Transcription"
        )
    }

    func testGetLastTranscriptionIntentDescription() {
        let description = GetLastTranscriptionIntent.description
        XCTAssertNotNil(description)
    }

    // MARK: - SearchTranscriptionsIntent

    func testSearchTranscriptionsIntentTitle() {
        XCTAssertEqual(
            String(localized: SearchTranscriptionsIntent.title),
            "Search Transcriptions"
        )
    }

    func testSearchTranscriptionsIntentDescription() {
        let description = SearchTranscriptionsIntent.description
        XCTAssertNotNil(description)
    }

    func testSearchTranscriptionsIntentHasParameter() {
        var intent = SearchTranscriptionsIntent()
        intent.searchText = "hello"
        XCTAssertEqual(intent.searchText, "hello")
    }

    // MARK: - IntentError

    func testIntentErrorDescription() {
        let error = IntentError.noTranscriptions
        let description = String(localized: error.localizedStringResource)
        XCTAssertEqual(description, "No transcriptions found")
    }

    // MARK: - WhisperFlowShortcuts

    func testWhisperFlowShortcutsProviderHasThreeShortcuts() {
        let shortcuts = WhisperFlowShortcuts.appShortcuts
        XCTAssertEqual(shortcuts.count, 3)
    }
}
