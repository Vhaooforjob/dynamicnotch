import Foundation

enum AudioVolumeControlAvailability: Equatable {
    case available
    case requiresApplicationBundle
}

enum AudioVolumeControlRuntime {
    static var availability: AudioVolumeControlAvailability {
        guard Bundle.main.bundleURL.pathExtension == "app",
              Bundle.main.executableURL?.path.contains(".app/Contents/MacOS/") == true
        else { return .requiresApplicationBundle }
        return .available
    }
}

@MainActor
final class MediaState: ObservableObject {
    @Published private(set) var sources: [AudioSource] = []
    @Published private(set) var errorMessage: String?
    let volumeControlAvailability: AudioVolumeControlAvailability

    private let sourceProvider: AudioSourceProviding
    private let mixer: PerAppAudioMixing
    private var refreshTimer: Timer?
    private var applyTask: Task<Void, Never>?
    private var lastAudibleVolumes: [String: Float] = [:]

    init(
        sourceProvider: AudioSourceProviding = CoreAudioSourceProvider(),
        mixer: PerAppAudioMixing = CoreAudioPerAppMixer(),
        volumeControlAvailability: AudioVolumeControlAvailability = AudioVolumeControlRuntime.availability
    ) {
        self.sourceProvider = sourceProvider
        self.mixer = mixer
        self.volumeControlAvailability = volumeControlAvailability
    }

    func start() {
        guard refreshTimer == nil else { return }
        refresh()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        refreshTimer = timer
    }

    func stop() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        applyTask?.cancel()
        applyTask = nil
        mixer.stop()
    }

    func refresh() {
        let descriptors = sourceProvider.activeOutputSources()
        let existingVolumes = Dictionary(uniqueKeysWithValues: sources.map { ($0.id, $0.volume) })
        let updatedSources = descriptors.map {
            AudioSource(descriptor: $0, volume: existingVolumes[$0.id] ?? 1)
        }

        guard updatedSources != sources else { return }
        sources = updatedSources
        scheduleMixerUpdate(delay: .zero)
    }

    func setVolume(_ volume: Float, for sourceID: String) {
        guard volumeControlAvailability == .available else { return }
        guard let index = sources.firstIndex(where: { $0.id == sourceID }) else { return }
        let normalized = AudioSource.normalizedVolume(volume)
        guard sources[index].volume != normalized else { return }
        sources[index].volume = normalized
        if normalized > 0 {
            lastAudibleVolumes[sourceID] = normalized
        }
        errorMessage = nil
        scheduleMixerUpdate(delay: .milliseconds(120))
    }

    func toggleMute(for sourceID: String) {
        guard volumeControlAvailability == .available else { return }
        guard let source = sources.first(where: { $0.id == sourceID }) else { return }
        if source.volume > 0 {
            lastAudibleVolumes[sourceID] = source.volume
            setVolume(0, for: sourceID)
        } else {
            setVolume(lastAudibleVolumes[sourceID] ?? 1, for: sourceID)
        }
    }

    func dismissError() {
        errorMessage = nil
    }

    private func scheduleMixerUpdate(delay: Duration) {
        guard volumeControlAvailability == .available else { return }
        applyTask?.cancel()
        let configurations = sources
            .filter { $0.volume < 0.999 }
            .map(AudioMixConfiguration.init)

        applyTask = Task { @MainActor [weak self] in
            do {
                if delay != .zero {
                    try await Task.sleep(for: delay)
                }
                guard !Task.isCancelled, let self else { return }
                try self.mixer.apply(configurations)
            } catch is CancellationError {
                return
            } catch {
                self?.errorMessage = error.localizedDescription
            }
        }
    }
}
