import XCTest
@testable import WhisperFlow

final class TranscriptionEngineTests: XCTestCase {
    func testTranscriptionSegmentProperties() {
        let segment = TranscriptionSegment(
            text: "Hello world",
            startTime: 0.0,
            endTime: 1.5
        )
        XCTAssertEqual(segment.text, "Hello world")
        XCTAssertEqual(segment.startTime, 0.0)
        XCTAssertEqual(segment.endTime, 1.5)
    }

    func testTranscriptionResultProperties() {
        let result = TranscriptionResult(
            text: "Hello world",
            segments: [
                TranscriptionSegment(text: "Hello world", startTime: 0, endTime: 1.5)
            ],
            language: "en",
            duration: 1.5
        )
        XCTAssertEqual(result.text, "Hello world")
        XCTAssertEqual(result.language, "en")
        XCTAssertEqual(result.duration, 1.5)
        XCTAssertEqual(result.segments.count, 1)
    }

    func testWhisperErrorDescriptions() {
        let loadError = WhisperError.modelLoadFailed("/path/to/model")
        XCTAssertNotNil(loadError.errorDescription)
        XCTAssertTrue(loadError.errorDescription!.contains("/path/to/model"))

        let contextError = WhisperError.contextNotInitialized
        XCTAssertNotNil(contextError.errorDescription)

        let inferenceError = WhisperError.inferenceFailed(code: -1)
        XCTAssertNotNil(inferenceError.errorDescription)
        XCTAssertTrue(inferenceError.errorDescription!.contains("-1"))
    }
}
