import AppKit

@MainActor
final class MenuBarController: NSObject, NSMenuDelegate {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private weak var notchController: NotchWindowController?
    private weak var settingsState: SettingsState?
    private let onOpenSettings: () -> Void
    private let menu = NSMenu()
    private let openPanelItem = NSMenuItem()
    private let settingsItem = NSMenuItem()
    private let quitItem = NSMenuItem()

    init(
        notchController: NotchWindowController,
        settingsState: SettingsState,
        onOpenSettings: @escaping () -> Void
    ) {
        self.notchController = notchController
        self.settingsState = settingsState
        self.onOpenSettings = onOpenSettings
        super.init()

        item.button?.image = NSImage(
            systemSymbolName: "rectangle.topthird.inset.filled",
            accessibilityDescription: "DynamicNotch"
        )
        configureMenu()
    }

    func menuWillOpen(_ menu: NSMenu) {
        updateMenuTitles()
    }

    func setVisible(_ isVisible: Bool) {
        item.isVisible = isVisible
    }

    @objc private func togglePanel() {
        notchController?.toggleExpanded()
    }

    @objc private func openSettings() {
        onOpenSettings()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    private func configureMenu() {
        menu.delegate = self

        openPanelItem.target = self
        openPanelItem.action = #selector(togglePanel)

        settingsItem.target = self
        settingsItem.action = #selector(openSettings)
        settingsItem.keyEquivalent = ","
        settingsItem.keyEquivalentModifierMask = [.command]

        quitItem.target = self
        quitItem.action = #selector(quit)
        quitItem.keyEquivalent = "q"
        quitItem.keyEquivalentModifierMask = [.command]

        menu.addItem(openPanelItem)
        menu.addItem(settingsItem)
        menu.addItem(.separator())
        menu.addItem(quitItem)
        updateMenuTitles()
        item.menu = menu
    }

    private func updateMenuTitles() {
        guard let settingsState else { return }
        openPanelItem.title = settingsState.text("openPanel")
        settingsItem.title = settingsState.text("settingsShort") + "…"
        quitItem.title = settingsState.text("quitApp")
    }
}
