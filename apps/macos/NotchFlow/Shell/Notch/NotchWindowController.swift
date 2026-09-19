import AppKit
import SwiftUI

@MainActor
final class NotchWindowController: NSObject {
    private let notchState: NotchState
    private let clipboardState: ClipboardState
    private let copyStackState: CopyStackState
    private var panel: NSPanel?

    init(notchState: NotchState, clipboardState: ClipboardState, copyStackState: CopyStackState) {
        self.notchState = notchState
        self.clipboardState = clipboardState
        self.copyStackState = copyStackState
    }

    func show() {
        if panel == nil {
            panel = makePanel()
        }
        positionPanel()
        panel?.orderFrontRegardless()
    }

    func toggleExpanded() {
        notchState.presentation = notchState.presentation == .expanded ? .compact : .expanded
        resizeForState()
        show()
    }

    private func makePanel() -> NSPanel {
        let view = NotchRootView(notchState: notchState, clipboardState: clipboardState, copyStackState: copyStackState)
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: NFLayout.compactWidth, height: NFLayout.compactHeight),
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

    private func resizeForState() {
        guard let panel else { return }
        let size = notchState.presentation == .expanded
            ? NSSize(width: NFLayout.expandedWidth, height: NFLayout.expandedHeight)
            : NSSize(width: NFLayout.compactWidth, height: NFLayout.compactHeight)
        panel.setContentSize(size)
        positionPanel()
    }

    private func positionPanel() {
        guard let panel else { return }
        let screen = NSScreen.main ?? NSScreen.screens.first
        guard let frame = screen?.visibleFrame else { return }
        let x = frame.midX - panel.frame.width / 2
        let y = frame.maxY - panel.frame.height - 6
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
