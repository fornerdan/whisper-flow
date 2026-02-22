import XCTest
@testable import WhisperCore
@testable import WhisperFlow

final class TextInjectorTests: XCTestCase {
    func testAccessibilityHelperIsTrustedReturnsBool() {
        // Just verify it doesn't crash — actual value depends on system state
        _ = AccessibilityHelper.isTrusted
    }

    func testAudioPermissionStatusCases() {
        // Verify all cases exist
        let statuses: [AudioPermissionStatus] = [.granted, .denied, .notDetermined]
        XCTAssertEqual(statuses.count, 3)
    }

    func testAudioCaptureErrorDescriptions() {
        let converterError = AudioCaptureError.converterCreationFailed
        XCTAssertNotNil(converterError.errorDescription)

        let engineError = AudioCaptureError.engineStartFailed("test reason")
        XCTAssertNotNil(engineError.errorDescription)
        XCTAssertTrue(engineError.errorDescription!.contains("test reason"))
    }

    func testModelErrorDescription() {
        let error = ModelError.modelNotFound("test-model")
        XCTAssertNotNil(error.errorDescription)
        XCTAssertTrue(error.errorDescription!.contains("test-model"))
    }
}
