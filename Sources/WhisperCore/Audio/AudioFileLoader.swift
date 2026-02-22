import AVFoundation

public enum AudioFileError: LocalizedError {
    case fileNotFound(String)
    case unsupportedFormat(String)
    case emptyFile
    case fileTooLong(TimeInterval)
    case conversionFailed(String)

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "Audio file not found: \(path)"
        case .unsupportedFormat(let ext):
            return "Unsupported audio format: \(ext)"
        case .emptyFile:
            return "Audio file contains no samples"
        case .fileTooLong(let duration):
            return "Audio file too long (\(Int(duration / 60)) min). Maximum is 30 minutes."
        case .conversionFailed(let reason):
            return "Audio conversion failed: \(reason)"
        }
    }
}

public final class AudioFileLoader {
    /// Maximum audio duration in seconds (30 minutes)
    public static let maxDuration: TimeInterval = 30 * 60

    /// Supported file extensions
    public static let supportedExtensions: Set<String> = [
        "wav", "mp3", "m4a", "aac", "flac", "mp4", "mov", "caf", "aiff", "aif"
    ]

    /// Check if a file extension is supported
    public static func isSupported(extension ext: String) -> Bool {
        supportedExtensions.contains(ext.lowercased())
    }

    /// Load an audio file and convert to 16kHz mono Float32 samples for Whisper
    public static func loadSamples(from url: URL) throws -> [Float] {
        let ext = url.pathExtension.lowercased()
        guard isSupported(extension: ext) else {
            throw AudioFileError.unsupportedFormat(ext)
        }

        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AudioFileError.fileNotFound(url.path)
        }

        let audioFile: AVAudioFile
        do {
            audioFile = try AVAudioFile(forReading: url)
        } catch {
            throw AudioFileError.conversionFailed(error.localizedDescription)
        }

        let sourceFormat = audioFile.processingFormat
        let frameCount = AVAudioFrameCount(audioFile.length)

        guard frameCount > 0 else {
            throw AudioFileError.emptyFile
        }

        // Check duration
        let duration = Double(frameCount) / sourceFormat.sampleRate
        guard duration <= maxDuration else {
            throw AudioFileError.fileTooLong(duration)
        }

        // Target format: 16kHz mono Float32 (same as AudioCaptureEngine)
        let targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: AudioCaptureEngine.whisperSampleRate,
            channels: AudioCaptureEngine.whisperChannels,
            interleaved: false
        )!

        // Read all samples from file
        guard let sourceBuffer = AVAudioPCMBuffer(pcmFormat: sourceFormat, frameCapacity: frameCount) else {
            throw AudioFileError.conversionFailed("Failed to create source buffer")
        }
        try audioFile.read(into: sourceBuffer)

        // If already in target format, extract directly
        if sourceFormat.sampleRate == AudioCaptureEngine.whisperSampleRate
            && sourceFormat.channelCount == AudioCaptureEngine.whisperChannels
            && sourceFormat.commonFormat == .pcmFormatFloat32 {
            return extractSamples(from: sourceBuffer)
        }

        // Convert to target format
        guard let converter = AVAudioConverter(from: sourceFormat, to: targetFormat) else {
            throw AudioFileError.conversionFailed("Failed to create audio converter")
        }

        let ratio = AudioCaptureEngine.whisperSampleRate / sourceFormat.sampleRate
        let outputFrameCapacity = AVAudioFrameCount(Double(frameCount) * ratio) + 1
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputFrameCapacity) else {
            throw AudioFileError.conversionFailed("Failed to create output buffer")
        }

        var conversionError: NSError?
        let status = converter.convert(to: outputBuffer, error: &conversionError) { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return sourceBuffer
        }

        if let conversionError {
            throw AudioFileError.conversionFailed(conversionError.localizedDescription)
        }
        guard status != .error else {
            throw AudioFileError.conversionFailed("Converter returned error status")
        }

        let samples = extractSamples(from: outputBuffer)
        guard !samples.isEmpty else {
            throw AudioFileError.emptyFile
        }

        return samples
    }

    private static func extractSamples(from buffer: AVAudioPCMBuffer) -> [Float] {
        guard let channelData = buffer.floatChannelData?[0] else { return [] }
        let count = Int(buffer.frameLength)
        return Array(UnsafeBufferPointer(start: channelData, count: count))
    }
}
