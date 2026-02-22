import AVFoundation
import Combine

enum AudioCaptureState {
    case idle
    case recording
    case error(String)
}

final class AudioCaptureEngine: ObservableObject {
    @Published private(set) var state: AudioCaptureState = .idle
    @Published private(set) var audioLevel: Float = 0

    private let audioEngine = AVAudioEngine()
    private var audioConverter: AVAudioConverter?
    private var pcmBuffer: [Float] = []
    private let bufferLock = NSLock()

    // Whisper expects 16kHz mono Float32
    static let whisperSampleRate: Double = 16000
    static let whisperChannels: AVAudioChannelCount = 1

    private lazy var whisperFormat: AVAudioFormat = {
        AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: Self.whisperSampleRate,
            channels: Self.whisperChannels,
            interleaved: false
        )!
    }()

    func startRecording() throws {
        guard state != .recording else { return }

        pcmBuffer.removeAll()

        let inputNode = audioEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // Create converter from device format to whisper format
        guard let converter = AVAudioConverter(from: inputFormat, to: whisperFormat) else {
            throw AudioCaptureError.converterCreationFailed
        }
        self.audioConverter = converter

        // Install tap on input node
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
            self?.processAudioBuffer(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        DispatchQueue.main.async {
            self.state = .recording
        }
    }

    func stopRecording() -> [Float] {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        audioConverter = nil

        DispatchQueue.main.async {
            self.state = .idle
            self.audioLevel = 0
        }

        bufferLock.lock()
        let samples = pcmBuffer
        pcmBuffer.removeAll()
        bufferLock.unlock()

        return samples
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let converter = audioConverter else { return }

        // Calculate audio level for UI visualization
        if let channelData = buffer.floatChannelData?[0] {
            let frameCount = Int(buffer.frameLength)
            var sum: Float = 0
            for i in 0..<frameCount {
                sum += abs(channelData[i])
            }
            let avgLevel = sum / Float(max(frameCount, 1))
            DispatchQueue.main.async {
                self.audioLevel = avgLevel
            }
        }

        // Convert to 16kHz mono
        let ratio = whisperFormat.sampleRate / buffer.format.sampleRate
        let outputFrameCapacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1

        guard let outputBuffer = AVAudioPCMBuffer(
            pcmFormat: whisperFormat,
            frameCapacity: outputFrameCapacity
        ) else { return }

        var error: NSError?
        let status = converter.convert(to: outputBuffer, error: &error) { inNumPackets, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }

        guard status != .error, error == nil else { return }

        // Append converted samples to our buffer
        if let channelData = outputBuffer.floatChannelData?[0] {
            let frameCount = Int(outputBuffer.frameLength)
            let samples = Array(UnsafeBufferPointer(start: channelData, count: frameCount))

            bufferLock.lock()
            pcmBuffer.append(contentsOf: samples)
            bufferLock.unlock()
        }
    }
}

enum AudioCaptureError: LocalizedError {
    case converterCreationFailed
    case engineStartFailed(String)

    var errorDescription: String? {
        switch self {
        case .converterCreationFailed:
            return "Failed to create audio format converter"
        case .engineStartFailed(let reason):
            return "Failed to start audio engine: \(reason)"
        }
    }
}
