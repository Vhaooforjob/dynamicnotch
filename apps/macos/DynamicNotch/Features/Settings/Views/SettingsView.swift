import SwiftUI

private enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case notch
    case clipboard
    case capture
    case translation
    case media
    case calendar
    case agents
    case shortcuts
    case sync
    case privacy
    case advanced
    case about

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .general: "gear"
        case .notch: "rectangle.topthird.inset.filled"
        case .clipboard: "square.on.square"
        case .capture: "viewfinder"
        case .translation: "character.book.closed"
        case .media: "play.circle"
        case .calendar: "calendar"
        case .agents: "cpu"
        case .shortcuts: "command"
        case .sync: "arrow.triangle.2.circlepath"
        case .privacy: "hand.raised"
        case .advanced: "slider.horizontal.3"
        case .about: "info.circle"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var state: SettingsState
    let onClearClipboard: () -> Void
    @State private var selectedSection: SettingsSection = .general

    var body: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
            detail
        }
        .frame(width: 760, height: 520)
        .background(settingsBackground)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: NFSpacing.xs) {
            ForEach(SettingsSection.allCases) { section in
                Button {
                    selectedSection = section
                } label: {
                    Label(title(for: section), systemImage: section.icon)
                        .font(NFTypography.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, NFSpacing.md)
                        .padding(.vertical, NFSpacing.sm)
                        .background(
                            selectedSection == section ? NFTheme.accent.opacity(0.18) : Color.clear,
                            in: RoundedRectangle(cornerRadius: NFRadius.sm, style: .continuous)
                        )
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
        .padding(NFSpacing.md)
        .frame(width: 190)
    }

    private var detail: some View {
        VStack(alignment: .leading, spacing: NFSpacing.lg) {
            Text(title(for: selectedSection))
                .font(.system(size: 22, weight: .semibold))
            ScrollView {
                VStack(spacing: NFSpacing.md) {
                    switch selectedSection {
                    case .general:
                        settingsCard {
                            Toggle(state.text("launchAtLogin"), isOn: $state.launchAtLogin)
                            Toggle(state.text("showInMenuBar"), isOn: $state.showInMenuBar)
                            Toggle(state.text("startMinimized"), isOn: $state.startMinimized)
                            Picker(state.text("language"), selection: $state.appLanguage) {
                                ForEach(AppLanguage.allCases) { language in
                                    Text(language.label).tag(language)
                                }
                            }
                            Picker(state.text("theme"), selection: $state.appearanceMode) {
                                Text(state.text("system")).tag(AppearanceMode.system)
                                Text(state.text("light")).tag(AppearanceMode.light)
                                Text(state.text("dark")).tag(AppearanceMode.dark)
                            }
                            HStack {
                                Text(state.text("panelShortcut"))
                                Spacer()
                                NFShortcutBadge(title: "⌘⇧V")
                            }
                        }
                    case .clipboard:
                        settingsCard {
                            Toggle(state.text("pauseClipboard"), isOn: $state.pauseClipboardMonitoring)
                            Button(state.text("clearClipboard"), role: .destructive) {
                                onClearClipboard()
                            }
                        }
                    case .sync:
                        settingsCard {
                            Toggle(state.text("cloudSync"), isOn: $state.cloudSyncEnabled)
                                .disabled(!FeatureFlags.cloudSync)
                        }
                    case .privacy:
                        settingsCard {
                            Toggle(state.text("pauseClipboard"), isOn: $state.pauseClipboardMonitoring)
                            LabeledContent(state.text("ignoredApps")) {
                                Text("0")
                                    .foregroundStyle(.secondary)
                            }
                            LabeledContent(state.text("analytics")) {
                                Text(state.text("off"))
                                    .foregroundStyle(.secondary)
                            }
                            Button(state.text("clearClipboard"), role: .destructive) {
                                onClearClipboard()
                            }
                        }
                    case .notch, .capture, .translation, .media, .calendar, .agents, .shortcuts, .advanced, .about:
                        settingsCard {
                            LabeledContent(state.text("status")) {
                                Text(state.text("configuredLocally"))
                                    .foregroundStyle(.secondary)
                            }
                            Text(state.text("flaggedFeature"))
                                .font(NFTypography.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
        }
        .padding(NFSpacing.xl)
    }

    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: NFSpacing.md) {
            content()
        }
        .padding(NFSpacing.lg)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: NFRadius.md, style: .continuous))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func title(for section: SettingsSection) -> String {
        switch section {
        case .general: state.text("settingsGeneral")
        case .notch: state.text("settingsNotch")
        case .clipboard: state.text("settingsClipboard")
        case .capture: state.text("capture")
        case .translation: state.text("translation")
        case .media: state.text("media")
        case .calendar: state.text("calendar")
        case .agents: state.text("aiAgents")
        case .shortcuts: state.text("settingsShortcuts")
        case .sync: state.text("settingsSync")
        case .privacy: state.text("settingsPrivacy")
        case .advanced: state.text("settingsAdvanced")
        case .about: state.text("settingsAbout")
        }
    }

    private var settingsBackground: some View {
        Rectangle()
            .fill(.regularMaterial)
    }
}
