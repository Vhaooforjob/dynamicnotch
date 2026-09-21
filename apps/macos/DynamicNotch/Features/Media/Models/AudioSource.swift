import Foundation

struct AudioSourceDescriptor: Identifiable, Equatable, Sendable {
    let id: String
    let processObjectIDs: [UInt32]
    let processIDs: [Int32]
    let bundleID: String?
    let displayName: String
    let deviceNames: [String]

    init(
        id: String,
        processObjectIDs: [UInt32],
        processIDs: [Int32],
        bundleID: String?,
        displayName: String,
        deviceNames: [String]
    ) {
        self.id = id
        self.processObjectIDs = processObjectIDs.sorted()
        self.processIDs = processIDs.sorted()
        self.bundleID = bundleID
        self.displayName = displayName
        self.deviceNames = Array(Set(deviceNames)).sorted()
    }
}

struct AudioSource: Identifiable, Equatable {
    let descriptor: AudioSourceDescriptor
    var volume: Float

    var id: String { descriptor.id }

    init(descriptor: AudioSourceDescriptor, volume: Float = 1) {
        self.descriptor = descriptor
        self.volume = Self.normalizedVolume(volume)
    }

    static func normalizedVolume(_ value: Float) -> Float {
        min(max(value, 0), 1)
    }
}

struct AudioMixConfiguration: Equatable, Sendable {
    let sourceID: String
    let processObjectIDs: [UInt32]
    let volume: Float

    init(sourceID: String, processObjectIDs: [UInt32], volume: Float) {
        self.sourceID = sourceID
        self.processObjectIDs = processObjectIDs.sorted()
        self.volume = AudioSource.normalizedVolume(volume)
    }

    init(source: AudioSource) {
        sourceID = source.id
        processObjectIDs = source.descriptor.processObjectIDs
        volume = AudioSource.normalizedVolume(source.volume)
    }
}
