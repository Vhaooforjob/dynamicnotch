import CoreAudio
import Foundation

@MainActor
final class CoreAudioPerAppMixer: PerAppAudioMixing {
    private var session: MixerSession?
    private var activeConfigurations: [AudioMixConfiguration] = []

    func apply(_ configurations: [AudioMixConfiguration]) throws {
        let normalized = configurations
            .filter { !$0.processObjectIDs.isEmpty && $0.volume < 0.999 }
            .sorted { $0.sourceID < $1.sourceID }

        guard normalized != activeConfigurations else { return }
        stop()
        guard !normalized.isEmpty else { return }

        do {
            session = try buildSession(for: normalized)
            activeConfigurations = normalized
        } catch {
            stop()
            throw error
        }
    }

    func stop() {
        guard let session else {
            activeConfigurations = []
            return
        }

        AudioDeviceStop(session.aggregateDeviceID, session.ioProcID)
        AudioDeviceDestroyIOProcID(session.aggregateDeviceID, session.ioProcID)
        AudioHardwareDestroyAggregateDevice(session.aggregateDeviceID)
        for tapID in session.tapIDs {
            AudioHardwareDestroyProcessTap(tapID)
        }
        self.session = nil
        activeConfigurations = []
    }

    private func buildSession(
        for configurations: [AudioMixConfiguration]
    ) throws -> MixerSession {
        let outputDeviceID = try readDefaultOutputDevice()
        let outputDeviceUID = try readString(
            objectID: outputDeviceID,
            selector: kAudioDevicePropertyDeviceUID
        )

        var tapIDs: [AudioObjectID] = []
        var tapUIDs: [String] = []
        var layouts: [TapLayout] = []

        do {
            for configuration in configurations {
                let description = CATapDescription(
                    stereoMixdownOfProcesses: configuration.processObjectIDs
                )
                description.name = "DynamicNotch \(configuration.sourceID)"
                description.uuid = UUID()
                description.isPrivate = true
                description.muteBehavior = .muted

                var tapID = AudioObjectID(kAudioObjectUnknown)
                try check(
                    AudioHardwareCreateProcessTap(description, &tapID),
                    operation: "Create process tap"
                )
                tapIDs.append(tapID)

                let tapUID = try readString(
                    objectID: tapID,
                    selector: kAudioTapPropertyUID
                )
                let format: AudioStreamBasicDescription = try readScalar(
                    objectID: tapID,
                    selector: kAudioTapPropertyFormat
                )
                guard Self.supportsFloatPCM(format) else {
                    throw AudioMixerError.unsupportedFormat
                }

                tapUIDs.append(tapUID)
                layouts.append(
                    TapLayout(
                        gain: configuration.volume,
                        channels: max(Int(format.mChannelsPerFrame), 1),
                        isNonInterleaved: format.mFormatFlags & kAudioFormatFlagIsNonInterleaved != 0
                    )
                )
            }
        } catch {
            for tapID in tapIDs {
                AudioHardwareDestroyProcessTap(tapID)
            }
            throw error
        }

        var aggregateDeviceID = AudioObjectID(kAudioObjectUnknown)
        do {
            let aggregateUID = "app.dynamicnotch.mixer.\(UUID().uuidString)"
            let outputSubdevice: [String: Any] = [
                kAudioSubDeviceUIDKey: outputDeviceUID,
                kAudioSubDeviceInputChannelsKey: 0
            ]
            let tapList: [[String: Any]] = tapUIDs.map {
                [kAudioSubTapUIDKey: $0]
            }
            let aggregateDescription: [String: Any] = [
                kAudioAggregateDeviceNameKey: "DynamicNotch App Mixer",
                kAudioAggregateDeviceUIDKey: aggregateUID,
                kAudioAggregateDeviceSubDeviceListKey: [outputSubdevice],
                kAudioAggregateDeviceMainSubDeviceKey: outputDeviceUID,
                kAudioAggregateDeviceIsPrivateKey: true,
                kAudioAggregateDeviceIsStackedKey: false,
                kAudioAggregateDeviceTapListKey: tapList,
                kAudioAggregateDeviceTapAutoStartKey: false
            ]

            try check(
                AudioHardwareCreateAggregateDevice(
                    aggregateDescription as CFDictionary,
                    &aggregateDeviceID
                ),
                operation: "Create mixer device"
            )

            let outputFormat: AudioStreamBasicDescription = try readScalar(
                objectID: aggregateDeviceID,
                selector: kAudioDevicePropertyStreamFormat,
                scope: kAudioObjectPropertyScopeOutput
            )
            guard Self.supportsFloatPCM(outputFormat) else {
                throw AudioMixerError.unsupportedFormat
            }

            let outputLayout = OutputLayout(
                channels: max(Int(outputFormat.mChannelsPerFrame), 1),
                isNonInterleaved: outputFormat.mFormatFlags & kAudioFormatFlagIsNonInterleaved != 0
            )
            var ioProcID: AudioDeviceIOProcID?
            try check(
                AudioDeviceCreateIOProcIDWithBlock(
                    &ioProcID,
                    aggregateDeviceID,
                    nil
                ) { _, inputData, _, outputData, _ in
                    Self.mix(
                        inputData: inputData,
                        outputData: outputData,
                        tapLayouts: layouts,
                        outputLayout: outputLayout
                    )
                },
                operation: "Create mixer callback"
            )
            guard let ioProcID else {
                throw AudioMixerError.coreAudio(
                    operation: "Create mixer callback",
                    status: kAudioHardwareUnspecifiedError
                )
            }

            do {
                try check(
                    AudioDeviceStart(aggregateDeviceID, ioProcID),
                    operation: "Start app mixer"
                )
            } catch {
                AudioDeviceDestroyIOProcID(aggregateDeviceID, ioProcID)
                throw error
            }

            return MixerSession(
                aggregateDeviceID: aggregateDeviceID,
                ioProcID: ioProcID,
                tapIDs: tapIDs
            )
        } catch {
            if aggregateDeviceID != kAudioObjectUnknown {
                AudioHardwareDestroyAggregateDevice(aggregateDeviceID)
            }
            for tapID in tapIDs {
                AudioHardwareDestroyProcessTap(tapID)
            }
            throw error
        }
    }

    private func readDefaultOutputDevice() throws -> AudioObjectID {
        try readScalar(
            objectID: AudioObjectID(kAudioObjectSystemObject),
            selector: kAudioHardwarePropertyDefaultOutputDevice
        )
    }

    private func readScalar<Value>(
        objectID: AudioObjectID,
        selector: AudioObjectPropertySelector,
        scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal
    ) throws -> Value {
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
        try check(
            AudioObjectGetPropertyData(
                objectID,
                &address,
                0,
                nil,
                &dataSize,
                storage
            ),
            operation: "Read audio property"
        )
        return storage.load(as: Value.self)
    }

    private func readString(
        objectID: AudioObjectID,
        selector: AudioObjectPropertySelector
    ) throws -> String {
        var address = AudioObjectPropertyAddress(
            mSelector: selector,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var value: CFString = "" as CFString
        var dataSize = UInt32(MemoryLayout<CFString>.size)
        try check(
            withUnsafeMutablePointer(to: &value) {
                AudioObjectGetPropertyData(objectID, &address, 0, nil, &dataSize, $0)
            },
            operation: "Read audio identifier"
        )
        return value as String
    }

    private func check(_ status: OSStatus, operation: String) throws {
        guard status == noErr else {
            throw AudioMixerError.coreAudio(operation: operation, status: status)
        }
    }

    private static func supportsFloatPCM(_ format: AudioStreamBasicDescription) -> Bool {
        format.mFormatID == kAudioFormatLinearPCM
            && format.mFormatFlags & kAudioFormatFlagIsFloat != 0
            && format.mBitsPerChannel == 32
    }

    private nonisolated static func mix(
        inputData: UnsafePointer<AudioBufferList>,
        outputData: UnsafeMutablePointer<AudioBufferList>,
        tapLayouts: [TapLayout],
        outputLayout: OutputLayout
    ) {
        let inputs = UnsafeMutableAudioBufferListPointer(
            UnsafeMutablePointer(mutating: inputData)
        )
        let outputs = UnsafeMutableAudioBufferListPointer(outputData)

        for output in outputs {
            guard let data = output.mData else { continue }
            memset(data, 0, Int(output.mDataByteSize))
        }

        var inputBufferOffset = 0
        for layout in tapLayouts {
            let sourceBufferCount = layout.isNonInterleaved ? layout.channels : 1
            guard inputBufferOffset + sourceBufferCount <= inputs.count else { break }

            for outputChannel in 0..<min(outputLayout.channels, 2) {
                let sourceChannel = min(outputChannel, layout.channels - 1)
                let sourceBufferIndex = inputBufferOffset
                    + (layout.isNonInterleaved ? sourceChannel : 0)
                let sourceBuffer = inputs[sourceBufferIndex]
                guard let sourceData = sourceBuffer.mData else { continue }

                let sourceChannels = layout.isNonInterleaved ? 1 : layout.channels
                let sourceFrames = Int(sourceBuffer.mDataByteSize)
                    / MemoryLayout<Float>.size
                    / sourceChannels
                let sourceSamples = sourceData.assumingMemoryBound(to: Float.self)
                let sourceSampleChannel = layout.isNonInterleaved ? 0 : sourceChannel

                let outputBufferIndex = outputLayout.isNonInterleaved ? outputChannel : 0
                guard outputBufferIndex < outputs.count,
                      let destinationData = outputs[outputBufferIndex].mData
                else { continue }

                let destinationChannels = outputLayout.isNonInterleaved
                    ? 1
                    : max(Int(outputs[outputBufferIndex].mNumberChannels), 1)
                let destinationFrames = Int(outputs[outputBufferIndex].mDataByteSize)
                    / MemoryLayout<Float>.size
                    / destinationChannels
                let destinationSamples = destinationData.assumingMemoryBound(to: Float.self)
                let frameCount = min(sourceFrames, destinationFrames)
                let destinationSampleChannel = outputLayout.isNonInterleaved ? 0 : outputChannel

                AudioGainMath.add(
                    source: sourceSamples,
                    sourceChannels: sourceChannels,
                    sourceChannel: sourceSampleChannel,
                    destination: destinationSamples,
                    destinationChannels: destinationChannels,
                    destinationChannel: destinationSampleChannel,
                    frameCount: frameCount,
                    gain: layout.gain
                )
            }

            inputBufferOffset += sourceBufferCount
        }

        for output in outputs {
            guard let data = output.mData else { continue }
            let sampleCount = Int(output.mDataByteSize) / MemoryLayout<Float>.size
            let samples = data.assumingMemoryBound(to: Float.self)
            AudioGainMath.clamp(samples: samples, count: sampleCount)
        }
    }
}

enum AudioGainMath {
    nonisolated static func add(
        source: UnsafePointer<Float>,
        sourceChannels: Int,
        sourceChannel: Int,
        destination: UnsafeMutablePointer<Float>,
        destinationChannels: Int,
        destinationChannel: Int,
        frameCount: Int,
        gain: Float
    ) {
        guard sourceChannels > 0,
              destinationChannels > 0,
              sourceChannel >= 0,
              sourceChannel < sourceChannels,
              destinationChannel >= 0,
              destinationChannel < destinationChannels,
              frameCount > 0
        else { return }

        for frame in 0..<frameCount {
            let sourceIndex = frame * sourceChannels + sourceChannel
            let destinationIndex = frame * destinationChannels + destinationChannel
            destination[destinationIndex] += source[sourceIndex] * gain
        }
    }

    nonisolated static func clamp(samples: UnsafeMutablePointer<Float>, count: Int) {
        guard count > 0 else { return }
        for index in 0..<count {
            samples[index] = min(max(samples[index], -1), 1)
        }
    }
}

private struct MixerSession {
    let aggregateDeviceID: AudioObjectID
    let ioProcID: AudioDeviceIOProcID
    let tapIDs: [AudioObjectID]
}

private struct TapLayout: Sendable {
    let gain: Float
    let channels: Int
    let isNonInterleaved: Bool
}

private struct OutputLayout: Sendable {
    let channels: Int
    let isNonInterleaved: Bool
}
