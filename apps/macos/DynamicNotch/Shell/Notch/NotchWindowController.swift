import AppKit
import SwiftUI

@MainActor
final class NotchWindowController: NSObject {
    private let notchState: NotchState
    private let clipboardState: ClipboardState
    private let copyStackState: CopyStackState
    private let settingsState: SettingsState
    private let localStore: ClipboardLocalStore
    private var panel: NSPanel?
    private var localMouseDownMonitor: Any?
    private var globalMouseDownMonitor: Any?
    private var hoverCollapseTask: Task<Void, Never>?

    init(
        notchState: NotchState,
        clipboardState: ClipboardState,
        copyStackState: CopyStackState,
        settingsState: SettingsState,
        localStore: ClipboardLocalStore
    ) {
        self.notchState = notchState
        self.clipboardState = clipboardState
        self.copyStackState = copyStackState
        self.settingsState = settingsState
        self.localStore = localStore
    }

    func show() {
        if panel == nil {
            panel = makePanel()
            installOutsideClickMonitors()
        }
        positionPanel()
        panel?.orderFrontRegardless()
    }

    func toggleExpanded() {
        notchState.presentation = notchState.presentation == .expanded ? .compact : .expanded
        showWithoutRepositioning()
        resizeOnNextRunLoop(animated: true)
    }

    func expand() {
        guard notchState.presentation != .expanded else { return }
        notchState.presentation = .expanded
        showWithoutRepositioning()
        resizeOnNextRunLoop(animated: true)
    }

    func collapse() {
        guard notchState.presentation == .expanded else { return }
        notchState.presentation = .compact
        notchState.selectedPanel = .quickPanel
        resizeOnNextRunLoop(animated: true)
    }

    func close() {
        notchState.presentation = .compact
        notchState.selectedPanel = .quickPanel
        panel?.orderOut(nil)
    }

    func hideForSettings() {
        notchState.presentation = .compact
        notchState.selectedPanel = .quickPanel
        panel?.orderOut(nil)
    }

    func showCompact() {
        notchState.presentation = .compact
        notchState.selectedPanel = .quickPanel
        show()
    }

    func stop() {
        if let localMouseDownMonitor {
            NSEvent.removeMonitor(localMouseDownMonitor)
        }
        if let globalMouseDownMonitor {
            NSEvent.removeMonitor(globalMouseDownMonitor)
        }
        localMouseDownMonitor = nil
        globalMouseDownMonitor = nil
        hoverCollapseTask?.cancel()
        hoverCollapseTask = nil
    }

    private func makePanel() -> NSPanel {
        let view = NotchRootView(
            notchState: notchState,
            clipboardState: clipboardState,
            copyStackState: copyStackState,
            settingsState: settingsState,
            localStore: localStore,
            onExpand: { [weak self] in
                self?.expand()
            },
            onSelectPanel: { [weak self] panel in
                self?.selectPanel(panel)
            },
            onHoverChanged: { [weak self] isHovering in
                self?.handleHover(isHovering)
            }
        )
        let panel = InteractiveNotchPanel(
            contentRect: frameForCurrentState(),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        let hostingView = TransparentHostingView(rootView: view)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        hostingView.layer?.masksToBounds = true
        panel.contentView = hostingView
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = false
        panel.animationBehavior = .none
        return panel
    }

    private func showWithoutRepositioning() {
        if panel == nil {
            panel = makePanel()
            installOutsideClickMonitors()
        }
        panel?.orderFrontRegardless()
    }

    private func resizeOnNextRunLoop(animated: Bool) {
        Task { @MainActor [weak self] in
            await Task.yield()
            self?.resizeForState(animated: animated)
        }
    }

    private func resizeForState(animated: Bool = false) {
        guard let panel else { return }
        setPanelFrame(panel, to: frameForCurrentState(), animated: animated)
    }

    private func selectPanel(_ selectedPanel: NotchPanel) {
        guard notchState.selectedPanel != selectedPanel else { return }
        notchState.selectedPanel = selectedPanel
        resizeOnNextRunLoop(animated: true)
    }

    private func handleHover(_ isHovering: Bool) {
        hoverCollapseTask?.cancel()
        hoverCollapseTask = nil

        if isHovering {
            expand()
            return
        }
        guard notchState.presentation == .expanded else { return }

        hoverCollapseTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: .milliseconds(450))
            } catch {
                return
            }
            self?.collapse()
        }
    }

    private func positionPanel() {
        guard let panel else { return }
        setPanelFrame(panel, to: frameForCurrentState(), animated: false)
    }

    private func installOutsideClickMonitors() {
        localMouseDownMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            Task { @MainActor in
                self?.collapseIfClickIsOutside()
            }
            return event
        }

        globalMouseDownMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            Task { @MainActor in
                self?.collapseIfClickIsOutside()
            }
        }
    }

    private func collapseIfClickIsOutside() {
        guard notchState.presentation == .expanded,
              let panel,
              !panel.frame.contains(NSEvent.mouseLocation)
        else { return }

        collapse()
    }

    private func setPanelFrame(_ panel: NSPanel, to frame: NSRect, animated: Bool) {
        guard animated else {
            panel.setFrame(frame, display: true, animate: false)
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.22
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            context.allowsImplicitAnimation = true
            panel.animator().setFrame(frame, display: true)
        }
    }

    private func frameForCurrentState() -> NSRect {
        let screen = targetScreen()
        let screenFrame = screen?.frame ?? .zero
        let size = contentSize(for: screen)
        let topOffset = notchState.presentation == .expanded
            ? expandedTopOffset(for: screen)
            : 0
        return NSRect(
            x: screenFrame.midX - size.width / 2,
            y: screenFrame.maxY - size.height - topOffset,
            width: size.width,
            height: size.height
        )
    }

    private func targetScreen() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) })
            ?? panel?.screen
            ?? NSScreen.main
            ?? NSScreen.screens.first
    }

    private func expandedTopOffset(for screen: NSScreen?) -> CGFloat {
        guard let screen else { return 40 }
        let menuBarInset = screen.frame.maxY - screen.visibleFrame.maxY
        return max(menuBarInset, screen.safeAreaInsets.top, 34) + 4
    }

    private func contentSize(for screen: NSScreen?) -> NSSize {
        guard notchState.presentation == .expanded else {
            return compactSize(for: screen)
        }

        let height = notchState.selectedPanel == .quickPanel
            ? NFLayout.quickPanelHeight
            : NFLayout.detailPanelHeight
        return NSSize(width: NFLayout.expandedWidth, height: height)
    }

    private func compactSize(for screen: NSScreen?) -> NSSize {
        let measuredNotchWidth = notchWidth(for: screen)
        return NSSize(
            width: max(NFLayout.compactWidth, measuredNotchWidth + 48),
            height: NFLayout.compactHeight
        )
    }

    private func notchWidth(for screen: NSScreen?) -> CGFloat {
        guard let screen,
              let leftArea = screen.auxiliaryTopLeftArea,
              let rightArea = screen.auxiliaryTopRightArea
        else { return 0 }

        return max(0, rightArea.minX - leftArea.maxX)
    }

}

private final class TransparentHostingView<Content: View>: NSHostingView<Content> {
    override var isOpaque: Bool { false }
    override var intrinsicContentSize: NSSize { .zero }
}

private final class InteractiveNotchPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}
