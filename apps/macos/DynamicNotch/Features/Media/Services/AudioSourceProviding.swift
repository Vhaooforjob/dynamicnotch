import Foundation

@MainActor
protocol AudioSourceProviding: AnyObject {
    func activeOutputSources() -> [AudioSourceDescriptor]
}

@MainActor
protocol PerAppAudioMixing: AnyObject {
    func apply(_ configurations: [AudioMixConfiguration]) throws
    func stop()
}

enum AudioMixerError: LocalizedError {
    case coreAudio(operation: String, status: Int32)
    case unsupportedFormat

    var errorDescription: String? {
        switch self {
        case .coreAudio(let operation, let status):
            "\(operation) failed (Core Audio \(status))."
        case .unsupportedFormat:
            "The current output device does not expose a supported PCM format."
        }
    }
}
