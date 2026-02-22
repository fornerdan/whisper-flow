import XCTest
@testable import WhisperCore

final class AudioFileLoaderTests: XCTestCase {

    // MARK: - Format Support

    func testSupportedExtensions() {
        let expected: Set<String> = ["wav", "mp3", "m4a", "aac", "flac", "mp4", "mov", "caf", "aiff", "aif"]
        XCTAssertEqual(AudioFileLoader.supportedExtensions, expected)
    }

    func testIsSupportedReturnsTrueForKnownFormats() {
        XCTAssertTrue(AudioFileLoader.isSupported(extension: "wav"))
        XCTAssertTrue(AudioFileLoader.isSupported(extension: "mp3"))
        XCTAssertTrue(AudioFileLoader.isSupported(extension: "m4a"))
        XCTAssertTrue(AudioFileLoader.isSupported(extension: "MP4"))
        XCTAssertTrue(AudioFileLoader.isSupported(extension: "FLAC"))
    }

    func testIsSupportedReturnsFalseForUnknownFormats() {
        XCTAssertFalse(AudioFileLoader.isSupported(extension: "txt"))
        XCTAssertFalse(AudioFileLoader.isSupported(extension: "pdf"))
        XCTAssertFalse(AudioFileLoader.isSupported(extension: "ogg"))
        XCTAssertFalse(AudioFileLoader.isSupported(extension: ""))
    }

    // MARK: - Error Cases

    func testLoadSamplesThrowsForUnsupportedFormat() {
        let url = URL(fileURLWithPath: "/tmp/test.ogg")
        XCTAssertThrowsError(try AudioFileLoader.loadSamples(from: url)) { error in
            guard case AudioFileError.unsupportedFormat(let ext) = error else {
                XCTFail("Expected unsupportedFormat error, got \(error)")
                return
            }
            XCTAssertEqual(ext, "ogg")
        }
    }

    func testLoadSamplesThrowsForMissingFile() {
        let url = URL(fileURLWithPath: "/tmp/nonexistent_audio_\(UUID().uuidString).wav")
        XCTAssertThrowsError(try AudioFileLoader.loadSamples(from: url)) { error in
            guard case AudioFileError.fileNotFound = error else {
                XCTFail("Expected fileNotFound error, got \(error)")
                return
            }
        }
    }

    // MARK: - Max Duration

    func testMaxDurationIs30Minutes() {
        XCTAssertEqual(AudioFileLoader.maxDuration, 1800)
    }

    // MARK: - Error Descriptions

    func testErrorDescriptions() {
        let errors: [(AudioFileError, String)] = [
            (.emptyFile, "Audio file contains no samples"),
            (.unsupportedFormat("ogg"), "Unsupported audio format: ogg"),
        ]

        for (error, expected) in errors {
            XCTAssertEqual(error.errorDescription, expected)
        }
    }
}
