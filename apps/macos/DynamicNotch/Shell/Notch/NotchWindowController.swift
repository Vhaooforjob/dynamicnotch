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
        resizeForState(animated: true)
        show()
    }

    func expand() {
        guard notchState.presentation != .expanded else { return }
        notchState.presentation = .expanded
        resizeForState(animated: true)
        show()
    }

    func collapse() {
        guard notchState.presentation == .expanded else { return }
        notchState.presentation = .compact
        resizeForState(animated: true)
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
            }
        )
        let panel = NSPanel(
            contentRect: frameForCurrentState(),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.contentView = NSHostingView(rootView: view)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hidesOnDeactivate = false
        panel.hasShadow = true
        return panel
    }

    private func resizeForState(animated: Bool = false) {
        guard let panel else { return }
        setPanelFrame(panel, to: frameForCurrentState(), animated: animated)
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
        let screen = NSScreen.main ?? NSScreen.screens.first
        let screenFrame = screen?.visibleFrame ?? .zero
        let size = notchState.presentation == .expanded
            ? NSSize(width: NFLayout.expandedWidth, height: NFLayout.expandedHeight)
            : NSSize(width: NFLayout.compactWidth, height: NFLayout.compactHeight)
        return NSRect(
            x: screenFrame.midX - size.width / 2,
            y: screenFrame.maxY - size.height - 6,
            width: size.width,
            height: size.height
        )
    }
}
