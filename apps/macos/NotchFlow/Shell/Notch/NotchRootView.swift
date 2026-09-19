import SwiftUI

struct NotchRootView: View {
    @ObservedObject var notchState: NotchState
    @ObservedObject var clipboardState: ClipboardState
    @ObservedObject var copyStackState: CopyStackState

    var body: some View {
        VStack(spacing: 0) {
            if notchState.presentation == .expanded {
                ExpandedNotchView(clipboardState: clipboardState, copyStackState: copyStackState)
            } else {
                CompactNotchView(count: clipboardState.items.count)
            }
        }
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: NFRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: NFRadius.lg, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
        .onHover { hovering in
            if hovering && notchState.presentation == .idle {
                notchState.presentation = .compact
            }
        }
        .onTapGesture {
            withAnimation(NFAnimation.panel) {
                notchState.presentation = notchState.presentation == .expanded ? .compact : .expanded
            }
        }
    }
}

private struct CompactNotchView: View {
    let count: Int

    var body: some View {
        HStack(spacing: NFSpacing.sm) {
            Image(systemName: "square.on.square")
            Text("NotchFlow")
            Spacer()
            Text("\(count)")
                .foregroundStyle(.secondary)
        }
        .font(NFTypography.body)
        .padding(.horizontal, NFSpacing.lg)
        .frame(width: NFLayout.compactWidth, height: NFLayout.compactHeight)
        .accessibilityLabel("NotchFlow clipboard panel")
    }
}

private struct ExpandedNotchView: View {
    @ObservedObject var clipboardState: ClipboardState
    @ObservedObject var copyStackState: CopyStackState

    var body: some View {
        VStack(spacing: NFSpacing.md) {
            HStack {
                Text("Clipboard")
                    .font(NFTypography.title)
                Spacer()
                Button {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                } label: {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open Settings")
            }
            ClipboardPanelView(state: clipboardState, copyStackState: copyStackState)
        }
        .padding(NFSpacing.lg)
        .frame(width: NFLayout.expandedWidth, height: NFLayout.expandedHeight)
    }
}
