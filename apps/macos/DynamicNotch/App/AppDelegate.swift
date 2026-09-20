import AppKit
import ServiceManagement
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    lazy var container = DependencyContainer()
    private var menuBarController: MenuBarController?
    private var settingsWindowController: NSWindowController?
    private weak var settingsWindow: NSWindow?
    private var didStart = false

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard !isRunningUnitTests else { return }
        didStart = true
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
        menuBarController = MenuBarController(
            notchController: container.notchController,
            settingsState: container.settingsState,
            onOpenSettings: { [weak self] in self?.openSettings() }
        )
        configureSettingsActions()
        if !container.settingsState.startMinimized {
            container.notchController.show()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        guard didStart else { return }
        NotificationCenter.default.removeObserver(self)
        container.stop()
    }

    func openSettings() {
        let windowController = settingsWindowController ?? makeSettingsWindowController()
        settingsWindowController = windowController
        guard let window = windowController.window else { return }

        window.title = container.settingsState.text("settingsShort")
        container.hideNotchForSettings()
        NSApp.activate()
        windowController.showWindow(nil)
        window.makeKeyAndOrderFront(nil)
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

    private func makeSettingsWindowController() -> NSWindowController {
        let rootView = SettingsView(
            state: container.settingsState,
            onClearClipboard: container.clearClipboardHistory
        )
        .preferredColorScheme(container.settingsState.appearanceMode.colorScheme)

        let contentSize = NSSize(width: 760, height: 520)
        let hostingView = FixedSizeHostingView(rootView: rootView)
        hostingView.frame = NSRect(origin: .zero, size: contentSize)
        hostingView.autoresizingMask = [.width, .height]

        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: contentSize),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.contentView = hostingView
        window.tabbingMode = .disallowed
        window.center()
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("DynamicNotch.Settings")
        return NSWindowController(window: window)
    }

    private var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
            || NSClassFromString("XCTestCase") != nil
    }
}

private final class FixedSizeHostingView<Content: View>: NSHostingView<Content> {
    override var intrinsicContentSize: NSSize { .zero }
}
