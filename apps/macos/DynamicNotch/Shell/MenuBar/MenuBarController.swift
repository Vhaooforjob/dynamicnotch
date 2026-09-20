import AppKit

@MainActor
final class MenuBarController {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private weak var notchController: NotchWindowController?

    init(notchController: NotchWindowController) {
        self.notchController = notchController
        item.button?.image = NSImage(systemSymbolName: "rectangle.topthird.inset.filled", accessibilityDescription: "DynamicNotch")
        item.button?.target = self
        item.button?.action = #selector(toggle)
    }

    @objc private func toggle() {
        notchController?.toggleExpanded()
    }
}
