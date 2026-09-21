import AppKit
import SwiftUI

@MainActor
final class NotchWindowController: NSObject {
    private let notchState: NotchState
    private let clipboardState: ClipboardState
    private let copyStackState: CopyStackState
    private let mediaState: MediaState
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
        mediaState: MediaState,
        settingsState: SettingsState,
        localStore: ClipboardLocalStore
    ) {
        self.notchState = notchState
        self.clipboardState = clipboardState
        self.copyStackState = copyStackState
        self.mediaState = mediaState
        self.settingsState = settingsState
        self.localStore = localStore
    }

    func show() {
        if panel == nil {
            panel = makePanel()
            installOutsideClickMonitors()
        } else {
            positionPanel()
        }
        panel?.orderFrontRegardless()
    }

    func toggleExpanded() {
        let anchorFrame = visiblePanelFrame
        notchState.presentation = notchState.presentation == .expanded ? .compact : .expanded
        showWithoutRepositioning()
        resizeOnNextRunLoop(animated: true, anchoredTo: anchorFrame)
    }

    func expand() {
        guard notchState.presentation != .expanded else { return }
        let anchorFrame = visiblePanelFrame
        notchState.presentation = .expanded
        showWithoutRepositioning()
        resizeOnNextRunLoop(animated: true, anchoredTo: anchorFrame)
    }

    func collapse() {
        guard notchState.presentation == .expanded else { return }
        let anchorFrame = visiblePanelFrame
        notchState.presentation = .compact
        notchState.selectedPanel = .quickPanel
        resizeOnNextRunLoop(animated: true, anchoredTo: anchorFrame)
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
            mediaState: mediaState,
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
        let hostingView = NSHostingView(rootView: view)
        hostingView.sizingOptions = []
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

    private var visiblePanelFrame: NSRect? {
        guard let panel, panel.isVisible else { return nil }
        return panel.frame
    }

    private func resizeOnNextRunLoop(animated: Bool, anchoredTo anchorFrame: NSRect? = nil) {
        Task { @MainActor [weak self] in
            await Task.yield()
            self?.resizeForState(animated: animated, anchoredTo: anchorFrame)
        }
    }

    private func resizeForState(animated: Bool = false, anchoredTo anchorFrame: NSRect? = nil) {
        guard let panel else { return }
        setPanelFrame(
            panel,
            to: frameForCurrentState(anchoredTo: anchorFrame),
            animated: animated
        )
    }

    private func selectPanel(_ selectedPanel: NotchPanel) {
        guard notchState.selectedPanel != selectedPanel else { return }
        let anchorFrame = visiblePanelFrame
        notchState.selectedPanel = selectedPanel
        resizeOnNextRunLoop(animated: true, anchoredTo: anchorFrame)
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
            panel.setFrame(frame, display: false, animate: false)
            return
        }

        guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else {
            panel.setFrame(frame, display: false, animate: false)
            return
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(
                controlPoints: 0.2,
                0.9,
                0.2,
                1
            )
            context.allowsImplicitAnimation = true
            panel.animator().setFrame(frame, display: true)
        }
    }

    private func frameForCurrentState(anchoredTo anchorFrame: NSRect? = nil) -> NSRect {
        let screen = screen(containing: anchorFrame) ?? targetScreen()
        let screenFrame = screen?.frame ?? .zero
        let size = contentSize(for: screen)
        return NotchFrameCalculator.frame(
            contentSize: size,
            screenFrame: screenFrame,
            anchorFrame: anchorFrame
        )
    }

    private func screen(containing frame: NSRect?) -> NSScreen? {
        guard let frame else { return nil }
        let anchorPoint = CGPoint(x: frame.midX, y: frame.maxY - 1)
        return NSScreen.screens.first(where: { $0.frame.contains(anchorPoint) })
    }

    private func targetScreen() -> NSScreen? {
        let mouseLocation = NSEvent.mouseLocation
        return NSScreen.screens.first(where: { $0.frame.contains(mouseLocation) })
            ?? panel?.screen
            ?? NSScreen.main
            ?? NSScreen.screens.first
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

enum NotchFrameCalculator {
    static func frame(
        contentSize: NSSize,
        screenFrame: NSRect,
        anchorFrame: NSRect?
    ) -> NSRect {
        let centerX = anchorFrame?.midX ?? screenFrame.midX
        let topY = anchorFrame?.maxY ?? screenFrame.maxY
        return NSRect(
            x: centerX - contentSize.width / 2,
            y: topY - contentSize.height,
            width: contentSize.width,
            height: contentSize.height
        )
    }
}

private final class InteractiveNotchPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}
