import Foundation

@MainActor
final class DependencyContainer {
    let appState = AppState()
    let notchState = NotchState()
    let settingsState = SettingsState()
    let clipboardState = ClipboardState()
    let copyStackState = CopyStackState()
    let localStore: ClipboardLocalStore
    let clipboardMonitor: ClipboardMonitorService
    let shortcutManager = ShortcutManager()
    let notchController: NotchWindowController

    init() {
        localStore = ClipboardLocalStore()
        clipboardMonitor = ClipboardMonitorService(store: localStore)
        notchController = NotchWindowController(notchState: notchState, clipboardState: clipboardState, copyStackState: copyStackState)
    }

    func start() {
        clipboardState.items = localStore.fetchItems()
        clipboardMonitor.onItemsChanged = { [weak self] items in
            Task { @MainActor in self?.clipboardState.items = items }
        }
        clipboardMonitor.start()
        shortcutManager.registerDefaultShortcut { [weak self] in
            Task { @MainActor in self?.notchController.toggleExpanded() }
        }
    }

    func stop() {
        clipboardMonitor.stop()
        shortcutManager.unregister()
    }
}
