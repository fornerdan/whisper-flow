import XCTest
@testable import WhisperCore
@testable import WhisperFlow

final class AudioCaptureTests: XCTestCase {
    func testWhisperSampleRate() {
        XCTAssertEqual(AudioCaptureEngine.whisperSampleRate, 16000)
    }

    func testWhisperChannelCount() {
        XCTAssertEqual(AudioCaptureEngine.whisperChannels, 1)
    }

    func testInitialState() {
        let engine = AudioCaptureEngine()
        if case .idle = engine.state {
            // Expected
        } else {
            XCTFail("Initial state should be idle")
        }
        XCTAssertEqual(engine.audioLevel, 0)
    }
}
