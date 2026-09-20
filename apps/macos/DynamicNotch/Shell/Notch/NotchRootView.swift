import SwiftUI

struct NotchRootView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var notchState: NotchState
    @ObservedObject var clipboardState: ClipboardState
    @ObservedObject var copyStackState: CopyStackState
    @ObservedObject var settingsState: SettingsState
    let localStore: ClipboardLocalStore
    let onExpand: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if notchState.presentation == .expanded {
                ExpandedNotchView(
                    clipboardState: clipboardState,
                    copyStackState: copyStackState,
                    settingsState: settingsState,
                    localStore: localStore
                )
                .transition(.scale(scale: 0.97, anchor: .top).combined(with: .opacity))
            } else {
                CompactNotchView(count: clipboardState.items.count)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(NFAnimation.panel) {
                            onExpand()
                        }
                    }
                    .transition(.opacity.combined(with: .scale(scale: 0.96, anchor: .top)))
            }
        }
        .animation(NFAnimation.content, value: notchState.presentation)
        .background(panelBackground, in: RoundedRectangle(cornerRadius: NFRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: NFRadius.lg, style: .continuous)
                .stroke(panelStroke, lineWidth: 1)
        )
        .preferredColorScheme(settingsState.appearanceMode.colorScheme)
    }

    private var panelBackground: Color {
        colorScheme == .light ? .white : Color(nsColor: .windowBackgroundColor)
    }

    private var panelStroke: Color {
        colorScheme == .light ? Color.black.opacity(0.12) : Color.white.opacity(0.14)
    }
}

private struct CompactNotchView: View {
    let count: Int

    var body: some View {
        HStack(spacing: NFSpacing.sm) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(Color.primary.opacity(0.7))
                .frame(width: 22, height: 3)
            Text("DynamicNotch")
            Spacer()
            Text("\(count)")
                .foregroundStyle(.secondary)
        }
        .font(NFTypography.body)
        .padding(.horizontal, NFSpacing.lg)
        .frame(width: NFLayout.compactWidth, height: NFLayout.compactHeight)
        .accessibilityLabel("DynamicNotch clipboard panel")
    }
}

private struct ExpandedNotchView: View {
    @ObservedObject var clipboardState: ClipboardState
    @ObservedObject var copyStackState: CopyStackState
    @ObservedObject var settingsState: SettingsState
    let localStore: ClipboardLocalStore

    var body: some View {
        VStack(spacing: NFSpacing.md) {
            HStack {
                Text(settingsState.text("clipboard"))
                    .font(NFTypography.title)
                Spacer()
                Button {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
                .accessibilityLabel(settingsState.text("openSettings"))
            }
            ClipboardPanelView(
                state: clipboardState,
                copyStackState: copyStackState,
                settingsState: settingsState,
                localStore: localStore
            )
        }
        .padding(NFSpacing.lg)
        .frame(width: NFLayout.expandedWidth, height: NFLayout.expandedHeight)
    }
}
