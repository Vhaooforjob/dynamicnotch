import XCTest
@testable import DynamicNotch

@MainActor
final class MediaStateTests: XCTestCase {
    func testVolumeIsClampedAndAppliedToMatchingSource() async throws {
        let provider = FakeAudioSourceProvider(sources: [Self.musicSource])
        let mixer = FakePerAppAudioMixer()
        let state = MediaState(
            sourceProvider: provider,
            mixer: mixer,
            volumeControlAvailability: .available
        )

        state.refresh()
        state.setVolume(-0.4, for: Self.musicSource.id)
        try await Task.sleep(for: .milliseconds(180))

        XCTAssertEqual(state.sources.first?.volume, 0)
        XCTAssertEqual(mixer.lastConfigurations, [
            AudioMixConfiguration(
                sourceID: Self.musicSource.id,
                processObjectIDs: Self.musicSource.processObjectIDs,
                volume: 0
            )
        ])
    }

    func testRefreshKeepsVolumeAndRemovesStoppedSourceFromMixer() async throws {
        let provider = FakeAudioSourceProvider(sources: [Self.musicSource])
        let mixer = FakePerAppAudioMixer()
        let state = MediaState(
            sourceProvider: provider,
            mixer: mixer,
            volumeControlAvailability: .available
        )

        state.refresh()
        state.setVolume(0.35, for: Self.musicSource.id)
        try await Task.sleep(for: .milliseconds(180))

        provider.sources = [
            AudioSourceDescriptor(
                id: Self.musicSource.id,
                processObjectIDs: [91],
                processIDs: [9001],
                bundleID: Self.musicSource.bundleID,
                displayName: "Music",
                deviceNames: ["External Display"]
            )
        ]
        state.refresh()
        await Task.yield()

        XCTAssertEqual(state.sources.first?.volume, 0.35)
        XCTAssertEqual(mixer.lastConfigurations.first?.processObjectIDs, [91])

        provider.sources = []
        state.refresh()
        await Task.yield()

        XCTAssertTrue(state.sources.isEmpty)
        XCTAssertEqual(mixer.lastConfigurations, [])
    }

    func testDescriptorNormalizesOrderingAndDuplicateDeviceNames() {
        let descriptor = AudioSourceDescriptor(
            id: "test",
            processObjectIDs: [7, 3],
            processIDs: [70, 30],
            bundleID: nil,
            displayName: "Test",
            deviceNames: ["Speakers", "Display", "Speakers"]
        )

        XCTAssertEqual(descriptor.processObjectIDs, [3, 7])
        XCTAssertEqual(descriptor.processIDs, [30, 70])
        XCTAssertEqual(descriptor.deviceNames, ["Display", "Speakers"])
    }

    func testMuteRestoresPreviousAudibleVolume() {
        let provider = FakeAudioSourceProvider(sources: [Self.musicSource])
        let state = MediaState(
            sourceProvider: provider,
            mixer: FakePerAppAudioMixer(),
            volumeControlAvailability: .available
        )

        state.refresh()
        state.setVolume(0.35, for: Self.musicSource.id)
        state.toggleMute(for: Self.musicSource.id)
        XCTAssertEqual(state.sources.first?.volume, 0)

        state.toggleMute(for: Self.musicSource.id)
        XCTAssertEqual(state.sources.first?.volume, 0.35)
    }

    func testGainMathMixesSelectedInterleavedChannelAndClampsOutput() {
        let source: [Float] = [0.8, -0.4, 0.6, 0.2]
        var destination: [Float] = [0.7, 0.8, 0.8, -0.2]

        source.withUnsafeBufferPointer { sourceBuffer in
            destination.withUnsafeMutableBufferPointer { destinationBuffer in
                AudioGainMath.add(
                    source: sourceBuffer.baseAddress!,
                    sourceChannels: 2,
                    sourceChannel: 0,
                    destination: destinationBuffer.baseAddress!,
                    destinationChannels: 2,
                    destinationChannel: 1,
                    frameCount: 2,
                    gain: 0.5
                )
                AudioGainMath.clamp(
                    samples: destinationBuffer.baseAddress!,
                    count: destinationBuffer.count
                )
            }
        }

        XCTAssertEqual(destination[0], 0.7, accuracy: 0.0001)
        XCTAssertEqual(destination[1], 1, accuracy: 0.0001)
        XCTAssertEqual(destination[2], 0.8, accuracy: 0.0001)
        XCTAssertEqual(destination[3], 0.1, accuracy: 0.0001)
    }

    func testVolumeControlDoesNotStartMixerOutsideApplicationBundle() async throws {
        let provider = FakeAudioSourceProvider(sources: [Self.musicSource])
        let mixer = FakePerAppAudioMixer()
        let state = MediaState(
            sourceProvider: provider,
            mixer: mixer,
            volumeControlAvailability: .requiresApplicationBundle
        )

        state.refresh()
        state.setVolume(0.2, for: Self.musicSource.id)
        try await Task.sleep(for: .milliseconds(150))

        XCTAssertEqual(state.sources.first?.volume, 1)
        XCTAssertTrue(mixer.applications.isEmpty)
    }

    func testNestedBrowserHelperResolvesToOuterApplicationBundle() {
        let path = "/Applications/Google Chrome.app/Contents/Frameworks/Google Chrome Framework.framework/Versions/Current/Helpers/Google Chrome Helper.app/Contents/MacOS/Google Chrome Helper"

        XCTAssertEqual(
            AudioApplicationResolver.applicationBundleURL(inExecutablePath: path)?.path,
            "/Applications/Google Chrome.app"
        )
    }

    private static let musicSource = AudioSourceDescriptor(
        id: "com.apple.Music",
        processObjectIDs: [42],
        processIDs: [4200],
        bundleID: "com.apple.Music",
        displayName: "Music",
        deviceNames: ["MacBook Pro Speakers"]
    )
}

@MainActor
private final class FakeAudioSourceProvider: AudioSourceProviding {
    var sources: [AudioSourceDescriptor]

    init(sources: [AudioSourceDescriptor]) {
        self.sources = sources
    }

    func activeOutputSources() -> [AudioSourceDescriptor] {
        sources
    }
}

@MainActor
private final class FakePerAppAudioMixer: PerAppAudioMixing {
    private(set) var applications: [[AudioMixConfiguration]] = []

    var lastConfigurations: [AudioMixConfiguration] {
        applications.last ?? []
    }

    func apply(_ configurations: [AudioMixConfiguration]) throws {
        applications.append(configurations)
    }

    func stop() {}
}
