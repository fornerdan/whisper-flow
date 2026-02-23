#if os(macOS)
import XCTest
@testable import WhisperCore

final class AudioDeviceTests: XCTestCase {

    func testAudioDeviceManagerInitializes() {
        let manager = AudioDeviceManager()
        // Enumeration should not crash, even if no devices are available
        XCTAssertNotNil(manager.availableDevices)
    }

    func testAudioDeviceManagerDefaultConsistency() {
        let manager = AudioDeviceManager()
        // If devices are found, at most one should be default
        let defaults = manager.availableDevices.filter { $0.isDefault }
        XCTAssertLessThanOrEqual(defaults.count, 1, "At most one device should be marked as default")
    }

    func testRefreshDevicesPopulatesUIDs() {
        let manager = AudioDeviceManager()
        for device in manager.availableDevices {
            XCTAssertFalse(device.uid.isEmpty, "Device '\(device.name)' should have a non-empty UID")
            XCTAssertFalse(device.name.isEmpty, "Device should have a non-empty name")
        }
    }

    func testRefreshDevicesIsIdempotent() {
        let manager = AudioDeviceManager()
        let first = manager.availableDevices
        manager.refreshDevices()
        let second = manager.availableDevices
        XCTAssertEqual(first, second, "Consecutive refreshes should return the same devices")
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
