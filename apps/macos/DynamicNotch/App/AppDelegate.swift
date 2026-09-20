import AppKit
import ServiceManagement

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let container = DependencyContainer()
    private var menuBarController: MenuBarController?
    private weak var settingsWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeKey(_:)),
            name: NSWindow.didBecomeKeyNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowWillClose(_:)),
            name: NSWindow.willCloseNotification,
            object: nil
        )
        container.start()
        menuBarController = MenuBarController(notchController: container.notchController)
        configureSettingsActions()
        if !container.settingsState.startMinimized {
            container.notchController.show()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        NotificationCenter.default.removeObserver(self)
        container.stop()
    }

    @objc private func windowDidBecomeKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              !(window is NSPanel)
        else { return }

        settingsWindow = window
        container.hideNotchForSettings()
    }

    @objc private func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              window === settingsWindow
        else { return }

        settingsWindow = nil
        Task { @MainActor [weak self] in
            await Task.yield()
            self?.container.showCompactNotch()
        }
    }

    private func configureSettingsActions() {
        let settings = container.settingsState
        settings.synchronizeLaunchAtLogin(SMAppService.mainApp.status == .enabled)
        menuBarController?.setVisible(settings.showInMenuBar)

        settings.onLaunchAtLoginChanged = { [weak settings] shouldLaunch in
            do {
                if shouldLaunch {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                settings?.synchronizeLaunchAtLogin(SMAppService.mainApp.status == .enabled)
            }
        }
        settings.onShowInMenuBarChanged = { [weak self] isVisible in
            self?.menuBarController?.setVisible(isVisible)
        }
    }
}
