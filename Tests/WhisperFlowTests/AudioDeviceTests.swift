#if os(macOS)
import XCTest
@testable import WhisperCore

final class AudioDeviceTests: XCTestCase {

    func testAudioDeviceManagerListsDevices() {
        let manager = AudioDeviceManager()
        // CI and real Macs should have at least one audio input device
        XCTAssertFalse(manager.availableDevices.isEmpty, "Should find at least one input device")
    }

    func testAudioDeviceManagerHasDefault() {
        let manager = AudioDeviceManager()
        let hasDefault = manager.availableDevices.contains { $0.isDefault }
        XCTAssertTrue(hasDefault, "At least one device should be marked as default")
    }

    func testRefreshDevicesPopulatesUIDs() {
        let manager = AudioDeviceManager()
        for device in manager.availableDevices {
            XCTAssertFalse(device.uid.isEmpty, "Device '\(device.name)' should have a non-empty UID")
            XCTAssertFalse(device.name.isEmpty, "Device should have a non-empty name")
        }
    }

    func testStartRecordingWithNilDeviceUsesDefault() {
        let engine = AudioCaptureEngine()
        // Passing nil for device should not crash — it just uses the system default.
        // We don't actually start recording (no mic permission in CI), but verify no throw on setup.
        // The actual startRecording may fail due to missing mic permissions, which is expected.
        XCTAssertNoThrow(try? engine.startRecording(preferredDeviceUID: nil))
    }

    func testStartRecordingWithInvalidDeviceThrows() {
        let engine = AudioCaptureEngine()
        do {
            try engine.startRecording(preferredDeviceUID: "nonexistent-device-uid-12345")
            XCTFail("Should have thrown deviceNotFound")
        } catch let error as AudioCaptureError {
            XCTAssertEqual(error, AudioCaptureError.deviceNotFound)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
}
#endif
