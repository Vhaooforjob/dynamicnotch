import AppKit
import SwiftUI

struct MediaPanelView: View {
    @ObservedObject var state: MediaState
    @ObservedObject var settingsState: SettingsState
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: NFSpacing.md) {
            toolbar

            if let errorMessage = state.errorMessage {
                errorBanner(errorMessage)
            }

            if state.volumeControlAvailability == .requiresApplicationBundle {
                runtimeWarning
            }

            if state.sources.isEmpty {
                emptyState
            } else {
                sourceList
            }

            Text(settingsState.text("systemAudioPermission"))
                .font(NFTypography.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var toolbar: some View {
        HStack(spacing: NFSpacing.sm) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)
            .focusable(false)

            VStack(alignment: .leading, spacing: 2) {
                Text(settingsState.text("activeAudioSources"))
                    .font(NFTypography.title)
                Text(settingsState.text("mediaSubtitle"))
                    .font(NFTypography.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var sourceList: some View {
        ScrollView {
            LazyVStack(spacing: NFSpacing.sm) {
                ForEach(state.sources) { source in
                    AudioSourceRow(
                        source: source,
                        settingsState: settingsState,
                        volumeControlEnabled: state.volumeControlAvailability == .available,
                        onVolumeChanged: { state.setVolume($0, for: source.id) },
                        onToggleMute: { state.toggleMute(for: source.id) }
                    )
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: NFSpacing.md) {
            Spacer()
            Image(systemName: "speaker.slash")
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(.secondary)
            Text(settingsState.text("noAudioSources"))
                .font(NFTypography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(spacing: NFSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(NFTheme.warning)
            Text(message)
                .font(NFTypography.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: state.dismissError) {
                Image(systemName: "xmark")
            }
            .buttonStyle(.plain)
        }
        .padding(NFSpacing.sm)
        .background(NFTheme.warning.opacity(0.12), in: RoundedRectangle(cornerRadius: NFRadius.sm))
    }

    private var runtimeWarning: some View {
        HStack(spacing: NFSpacing.sm) {
            Image(systemName: "info.circle.fill")
                .foregroundStyle(NFTheme.warning)
            Text(settingsState.text("audioMixerRequiresAppBundle"))
                .font(NFTypography.caption)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(NFSpacing.sm)
        .background(NFTheme.warning.opacity(0.12), in: RoundedRectangle(cornerRadius: NFRadius.sm))
    }
}

private struct AudioSourceRow: View {
    let source: AudioSource
    @ObservedObject var settingsState: SettingsState
    let volumeControlEnabled: Bool
    let onVolumeChanged: (Float) -> Void
    let onToggleMute: () -> Void

    var body: some View {
        NFCard {
            HStack(spacing: NFSpacing.md) {
                applicationIcon

                VStack(alignment: .leading, spacing: 3) {
                    Text(source.descriptor.displayName)
                        .font(NFTypography.body)
                        .lineLimit(1)
                    Text(sourceDescription)
                        .font(NFTypography.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(width: 170, alignment: .leading)

                Slider(value: volumeBinding, in: 0...1)
                    .controlSize(.small)
                    .disabled(!volumeControlEnabled)

                Text("\(Int((source.volume * 100).rounded()))%")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .frame(width: 42, alignment: .trailing)

                Button(action: onToggleMute) {
                    Image(systemName: source.volume == 0 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .frame(width: 20)
                }
                .buttonStyle(.plain)
                .disabled(!volumeControlEnabled)
                .help(settingsState.text(source.volume == 0 ? "unmute" : "mute"))
            }
        }
    }

    private var volumeBinding: Binding<Double> {
        Binding(
            get: { Double(source.volume) },
            set: { onVolumeChanged(Float($0)) }
        )
    }

    private var sourceDescription: String {
        if !source.descriptor.deviceNames.isEmpty {
            return source.descriptor.deviceNames.joined(separator: ", ")
        }
        return source.descriptor.bundleID ?? settingsState.text("audioDevice")
    }

    @ViewBuilder
    private var applicationIcon: some View {
        if let image = icon {
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)
        } else {
            NFIconTile(systemName: "speaker.wave.2.fill", color: NFTheme.success)
        }
    }

    private var icon: NSImage? {
        if let bundleID = source.descriptor.bundleID,
           let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        guard let pid = source.descriptor.processIDs.first else { return nil }
        return NSRunningApplication(processIdentifier: pid)?.icon
    }
}
