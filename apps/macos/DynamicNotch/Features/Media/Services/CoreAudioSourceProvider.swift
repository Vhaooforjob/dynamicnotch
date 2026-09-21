import AppKit
import CoreAudio

@MainActor
final class CoreAudioSourceProvider: AudioSourceProviding {
    func activeOutputSources() -> [AudioSourceDescriptor] {
        let processObjects = readObjectIDArray(
            objectID: AudioObjectID(kAudioObjectSystemObject),
            selector: kAudioHardwarePropertyProcessObjectList
        )

        let currentPID = getpid()
        let snapshots = processObjects.compactMap { objectID -> ProcessSnapshot? in
            guard let pid: pid_t = readScalar(
                objectID: objectID,
                selector: kAudioProcessPropertyPID
            ), pid != currentPID,
            let isRunning: UInt32 = readScalar(
                objectID: objectID,
                selector: kAudioProcessPropertyIsRunningOutput
            ), isRunning != 0
            else { return nil }

            let rawBundleID = readString(
                objectID: objectID,
                selector: kAudioProcessPropertyBundleID
            )
            let bundleID = rawBundleID.flatMap { $0.isEmpty ? nil : $0 }
            let application = AudioApplicationResolver.resolve(
                pid: pid,
                fallbackBundleID: bundleID
            )
            let devices = readObjectIDArray(
                objectID: objectID,
                selector: kAudioProcessPropertyDevices,
                scope: kAudioObjectPropertyScopeOutput
            )
            let deviceNames = devices.compactMap {
                readString(objectID: $0, selector: kAudioObjectPropertyName)
            }.filter { !$0.isEmpty }

            return ProcessSnapshot(
                objectID: objectID,
                pid: pid,
                bundleID: application.bundleID,
                displayName: application.displayName,
                deviceNames: deviceNames
            )
        }

        return Self.group(snapshots)
    }

    private static func group(_ snapshots: [ProcessSnapshot]) -> [AudioSourceDescriptor] {
        let grouped = Dictionary(grouping: snapshots) { snapshot in
            snapshot.bundleID ?? "pid:\(snapshot.pid)"
        }

        return grouped.map { key, values in
            AudioSourceDescriptor(
                id: key,
                processObjectIDs: values.map(\.objectID),
                processIDs: values.map(\.pid),
                bundleID: values.compactMap(\.bundleID).first,
                displayName: values.map(\.displayName).sorted().first ?? key,
                deviceNames: values.flatMap(\.deviceNames)
            )
        }
        .sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }

    private func readObjectIDArray(
        objectID: AudioObjectID,
        selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal
    ) -> [AudioObjectID] {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(
            objectID,
            &address,
            0,
            nil,
            &dataSize
        ) == noErr, dataSize > 0 else { return [] }

        let count = Int(dataSize) / MemoryLayout<AudioObjectID>.stride
        var values = Array(repeating: AudioObjectID(kAudioObjectUnknown), count: count)
        let status = values.withUnsafeMutableBytes { bytes in
            AudioObjectGetPropertyData(
                objectID,
                &address,
                0,
                nil,
                &dataSize,
                bytes.baseAddress!
            )
        }
        return status == noErr ? values : []
    }

    private func readScalar<Value>(
        objectID: AudioObjectID,
        selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal
    ) -> Value? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: scope,
            mElement: kAudioObjectPropertyElementMain
        )
        var dataSize = UInt32(MemoryLayout<Value>.size)
        let storage = UnsafeMutableRawPointer.allocate(
            byteCount: MemoryLayout<Value>.size,
            alignment: MemoryLayout<Value>.alignment
        )
        defer { storage.deallocate() }
        storage.initializeMemory(as: UInt8.self, repeating: 0, count: MemoryLayout<Value>.size)
        let status = AudioObjectGetPropertyData(
            objectID,
            &address,
            0,
            nil,
            &dataSize,
            storage
        )
        return status == noErr ? storage.load(as: Value.self) : nil
    }

    private func readString(
        objectID: AudioObjectID,
        selector: AudioObjectPropertySelector
    ) -> String? {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var value: CFString = "" as CFString
        var dataSize = UInt32(MemoryLayout<CFString>.size)
        let status = withUnsafeMutablePointer(to: &value) {
            AudioObjectGetPropertyData(objectID, &address, 0, nil, &dataSize, $0)
        }
        return status == noErr ? value as String : nil
    }
}

private struct ProcessSnapshot {
    let objectID: AudioObjectID
    let pid: pid_t
    let bundleID: String?
    let displayName: String
    let deviceNames: [String]
}
