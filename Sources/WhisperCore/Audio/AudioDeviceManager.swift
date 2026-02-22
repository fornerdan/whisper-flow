#if os(macOS)
import CoreAudio
import AVFoundation

public struct AudioInputDevice: Identifiable, Equatable {
    public let id: AudioDeviceID
    public let name: String
    public let uid: String
    public let isDefault: Bool
}

public final class AudioDeviceManager: ObservableObject {
    @Published public private(set) var availableDevices: [AudioInputDevice] = []

    public init() {
        refreshDevices()
    }

    public func refreshDevices() {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0, nil,
            &dataSize
        )
        guard status == noErr else { return }

        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0, nil,
            &dataSize,
            &deviceIDs
        )
        guard status == noErr else { return }

        let defaultInputID = Self.defaultInputDeviceID()

        var inputDevices: [AudioInputDevice] = []
        for deviceID in deviceIDs {
            // Check if device has input streams
            var streamAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStreams,
                mScope: kAudioObjectPropertyScopeInput,
                mElement: kAudioObjectPropertyElementMain
            )
            var streamSize: UInt32 = 0
            let streamStatus = AudioObjectGetPropertyDataSize(deviceID, &streamAddress, 0, nil, &streamSize)
            guard streamStatus == noErr, streamSize > 0 else { continue }

            let name = Self.deviceName(for: deviceID) ?? "Unknown Device"
            let uid = Self.deviceUID(for: deviceID) ?? ""

            inputDevices.append(AudioInputDevice(
                id: deviceID,
                name: name,
                uid: uid,
                isDefault: deviceID == defaultInputID
            ))
        }

        availableDevices = inputDevices
    }

    /// Look up a device ID from its persistent UID string.
    public static func deviceID(forUID uid: String) -> AudioDeviceID? {
        var translation = AudioValueTranslation(
            mInputData: UnsafeMutableRawPointer(mutating: (uid as NSString).utf8String!),
            mInputDataSize: UInt32(uid.utf8.count + 1),
            mOutputData: UnsafeMutableRawPointer.allocate(byteCount: MemoryLayout<AudioDeviceID>.size, alignment: MemoryLayout<AudioDeviceID>.alignment),
            mOutputDataSize: UInt32(MemoryLayout<AudioDeviceID>.size)
        )
        defer { translation.mOutputData.deallocate() }

        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDeviceForUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var size = UInt32(MemoryLayout<AudioValueTranslation>.size)
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0, nil,
            &size,
            &translation
        )

        guard status == noErr else { return nil }
        return translation.mOutputData.load(as: AudioDeviceID.self)
    }

    // MARK: - Private Helpers

    private static func defaultInputDeviceID() -> AudioDeviceID {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID: AudioDeviceID = 0
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0, nil,
            &size,
            &deviceID
        )
        return deviceID
    }

    private static func deviceName(for deviceID: AudioDeviceID) -> String? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var name: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        let status = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &size, &name)
        guard status == noErr, let cfName = name?.takeUnretainedValue() else { return nil }
        return cfName as String
    }

    private static func deviceUID(for deviceID: AudioDeviceID) -> String? {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var uid: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        let status = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, nil, &size, &uid)
        guard status == noErr, let cfUID = uid?.takeUnretainedValue() else { return nil }
        return cfUID as String
    }
}
#endif
