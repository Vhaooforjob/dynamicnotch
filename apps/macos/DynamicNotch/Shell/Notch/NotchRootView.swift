import SwiftUI

struct NotchRootView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var notchState: NotchState
    @ObservedObject var clipboardState: ClipboardState
    @ObservedObject var copyStackState: CopyStackState
    @ObservedObject var mediaState: MediaState
    @ObservedObject var settingsState: SettingsState
    let localStore: ClipboardLocalStore
    let onExpand: () -> Void
    let onSelectPanel: (NotchPanel) -> Void
    let onHoverChanged: (Bool) -> Void

    var body: some View {
        VStack(spacing: 0) {
            if notchState.presentation == .expanded {
                ExpandedNotchView(
                    notchState: notchState,
                    clipboardState: clipboardState,
                    copyStackState: copyStackState,
                    mediaState: mediaState,
                    settingsState: settingsState,
                    localStore: localStore,
                    onSelectPanel: onSelectPanel
                )
                .transition(
                    .scale(scale: 0.78, anchor: .top)
                        .combined(with: .opacity)
                )
            } else {
                CompactNotchView(count: clipboardState.items.count)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(NFAnimation.panel) {
                            onExpand()
                        }
                    }
                    .transition(
                        .scale(scale: 0.84, anchor: .top)
                            .combined(with: .opacity)
                    )
            }
        }
        .animation(NFAnimation.panel, value: notchState.presentation)
        .background(panelBackground, in: panelShape)
        .clipShape(panelShape)
        .contentShape(panelShape)
        .preferredColorScheme(settingsState.appearanceMode.colorScheme)
        .onHover(perform: onHoverChanged)
    }

    private var panelBackground: Color {
        colorScheme == .light ? NFTheme.lightBackground : NFTheme.darkBackground.opacity(0.96)
    }

    private var panelShape: NFPanelShape {
        return NFPanelShape(topRadius: 0, bottomRadius: NFRadius.xl)
    }
}

private struct NFPanelShape: Shape {
    let topRadius: CGFloat
    let bottomRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let top = min(topRadius, rect.width / 2, rect.height / 2)
        let bottom = min(bottomRadius, rect.width / 2, rect.height / 2)
        var path = Path()

        path.move(to: CGPoint(x: rect.minX + top, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - top, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + top),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - bottom))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - bottom, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + bottom, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - bottom),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + top))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + top, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        path.closeSubpath()

        return path
    }
}

private struct CompactNotchView: View {
    let count: Int

    var body: some View {
        HStack(spacing: NFSpacing.sm) {
            Image(systemName: "doc.on.doc")
                .foregroundStyle(NFTheme.accent)
            Spacer()
            Text("\(count)")
                .foregroundStyle(.secondary)
        }
        .font(NFTypography.body)
        .padding(.horizontal, NFSpacing.lg)
        .frame(width: NFLayout.compactWidth, height: NFLayout.compactHeight)
        .accessibilityLabel("Clipboard panel")
    }
}

private struct ExpandedNotchView: View {
    @ObservedObject var notchState: NotchState
    @ObservedObject var clipboardState: ClipboardState
    @ObservedObject var copyStackState: CopyStackState
    @ObservedObject var mediaState: MediaState
    @ObservedObject var settingsState: SettingsState
    let localStore: ClipboardLocalStore
    let onSelectPanel: (NotchPanel) -> Void

    var body: some View {
        VStack(spacing: NFSpacing.lg) {
            switch notchState.selectedPanel {
            case .quickPanel:
                QuickPanelView(
                    settingsState: settingsState,
                    onSelectPanel: onSelectPanel
                )
            case .clipboard:
                VStack(spacing: NFSpacing.md) {
                    PanelToolbar(
                        title: settingsState.text("clipboard"),
                        onBack: { onSelectPanel(.quickPanel) }
                    )
                    ClipboardPanelView(
                        state: clipboardState,
                        copyStackState: copyStackState,
                        settingsState: settingsState,
                        localStore: localStore,
                        onBack: { onSelectPanel(.quickPanel) }
                    )
                }
            case .media:
                MediaPanelView(
                    state: mediaState,
                    settingsState: settingsState,
                    onBack: { onSelectPanel(.quickPanel) }
                )
            case .capture, .calendar, .agents:
                FuturePanelView(
                    panel: notchState.selectedPanel,
                    settingsState: settingsState,
                    onBack: { onSelectPanel(.quickPanel) }
                )
            }
        }
        .padding(NFSpacing.lg)
        .frame(width: NFLayout.expandedWidth, height: expandedHeight)
    }

    private var expandedHeight: CGFloat {
        notchState.selectedPanel == .quickPanel ? NFLayout.quickPanelHeight : NFLayout.detailPanelHeight
    }
}

private struct QuickPanelView: View {
    @ObservedObject var settingsState: SettingsState
    let onSelectPanel: (NotchPanel) -> Void

    private var actions: [QuickAction] {
        [
            QuickAction(id: "clipboard", title: settingsState.text("clipboard"), icon: "doc.on.clipboard", color: NFTheme.accentBlue, destination: .panel(.clipboard), isEnabled: true),
            QuickAction(id: "screenshot", title: settingsState.text("screenshot"), icon: "viewfinder", color: NFTheme.accent, destination: .panel(.capture), isEnabled: FeatureFlags.smartCapture || FeatureFlags.scrollingScreenshot),
            QuickAction(id: "aiOcr", title: settingsState.text("aiOcr"), icon: "viewfinder.circle", color: NFTheme.accent, destination: .panel(.agents), isEnabled: FeatureFlags.agentApproval),
            QuickAction(id: "translate", title: settingsState.text("translate"), icon: "character.book.closed", color: NFTheme.accentBlue, destination: .panel(.capture), isEnabled: FeatureFlags.advancedTranslation),
            QuickAction(id: "search", title: settingsState.text("search"), icon: "magnifyingglass", color: NFTheme.accent, destination: .panel(.clipboard), isEnabled: true),
            QuickAction(id: "calendar", title: settingsState.text("calendar"), icon: "calendar", color: NFTheme.warning, destination: .panel(.calendar), isEnabled: false),
            QuickAction(id: "media", title: settingsState.text("media"), icon: "music.note", color: NFTheme.success, destination: .panel(.media), isEnabled: FeatureFlags.audioMixer || FeatureFlags.lyrics)
        ]
    }

    var body: some View {
        VStack(spacing: NFSpacing.md) {
            VStack(spacing: NFSpacing.xs) {
                Text(settingsState.text("quickPanel"))
                    .font(.system(size: 18, weight: .semibold))
                Text(settingsState.text("quickPanelSubtitle"))
                    .font(NFTypography.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: NFSpacing.md) {
                ForEach(actions) { action in
                    QuickActionTile(action: action) {
                        handle(action)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func handle(_ action: QuickAction) {
        guard action.isEnabled else { return }
        switch action.destination {
        case .panel(let panel):
            withAnimation(NFAnimation.content) {
                onSelectPanel(panel)
            }
        }
    }
}

private struct QuickAction: Identifiable {
    let id: String
    let title: String
    let icon: String
    let color: Color
    let destination: QuickActionDestination
    let isEnabled: Bool
}

private enum QuickActionDestination: Equatable {
    case panel(NotchPanel)
}

private struct QuickActionTile: View {
    let action: QuickAction
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            QuickActionTileContent(action: action)
                .contentShape(Rectangle())
                .opacity(action.isEnabled ? 1 : 0.55)
        }
        .buttonStyle(.plain)
        .focusable(false)
    }
}

private struct QuickActionTileContent: View {
    @Environment(\.colorScheme) private var colorScheme
    let action: QuickAction

    var body: some View {
        VStack(spacing: NFSpacing.sm) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: NFRadius.md, style: .continuous)
                    .fill(tileBackground)
                Image(systemName: action.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(action.color)
                if !action.isEnabled {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .padding(6)
                }
            }
            .frame(width: 58, height: 58)

            Text(action.title)
                .font(NFTypography.caption)
                .foregroundStyle(action.isEnabled ? Color.primary : Color.secondary)
                .lineLimit(1)
                .frame(width: 72)
        }
    }

    private var tileBackground: Color {
        colorScheme == .light ? .white : Color.white.opacity(0.08)
    }
}

private struct PanelToolbar: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: NFSpacing.sm) {
                    Image(systemName: "chevron.left")
                    Text(title)
                        .font(NFTypography.title)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .focusable(false)
            Spacer()
        }
    }
}

private struct FuturePanelView: View {
    let panel: NotchPanel
    @ObservedObject var settingsState: SettingsState
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: NFSpacing.md) {
            PanelToolbar(
                title: title,
                onBack: onBack
            )
            Spacer()
            NFIconTile(systemName: icon, color: NFTheme.accent)
                .scaleEffect(1.5)
            Text(title)
                .font(NFTypography.title)
            Text(settingsState.text("flaggedFeature"))
                .font(NFTypography.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 260)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var title: String {
        switch panel {
        case .quickPanel:
            settingsState.text("quickPanel")
        case .clipboard:
            settingsState.text("clipboard")
        case .capture:
            settingsState.text("capture")
        case .media:
            settingsState.text("media")
        case .calendar:
            settingsState.text("calendar")
        case .agents:
            settingsState.text("aiAgents")
        }
    }

    private var icon: String {
        switch panel {
        case .quickPanel:
            "sparkles"
        case .clipboard:
            "doc.on.clipboard"
        case .capture:
            "viewfinder"
        case .media:
            "play.circle.fill"
        case .calendar:
            "calendar"
        case .agents:
            "cpu"
        }
    }
}
