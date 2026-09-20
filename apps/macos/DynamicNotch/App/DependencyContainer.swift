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
        notchController = NotchWindowController(
            notchState: notchState,
            clipboardState: clipboardState,
            copyStackState: copyStackState,
            settingsState: settingsState,
            localStore: localStore
        )
        settingsState.onPauseClipboardMonitoringChanged = { [weak clipboardMonitor] isPaused in
            clipboardMonitor?.setPaused(isPaused)
        }
    }

    func start() {
        clipboardState.items = localStore.fetchItems()
        clipboardState.boards = localStore.fetchBoards()
        clipboardMonitor.onItemsChanged = { [weak self] items in
            Task { @MainActor in
                guard let self else { return }
                if let boardID = self.clipboardState.selectedBoardID {
                    self.clipboardState.items = self.localStore.fetchItems(boardID: boardID)
                } else {
                    self.clipboardState.items = items
                }
            }
        }
        clipboardMonitor.start()
        shortcutManager.registerDefaultShortcut { [weak self] in
            Task { @MainActor in self?.notchController.toggleExpanded() }
        }
    }

    func stop() {
        clipboardMonitor.stop()
        shortcutManager.unregister()
        notchController.stop()
    }

    func clearClipboardHistory() {
        localStore.clearItems()
        clipboardState.items = localStore.fetchItems(boardID: clipboardState.selectedBoardID)
    }
}
