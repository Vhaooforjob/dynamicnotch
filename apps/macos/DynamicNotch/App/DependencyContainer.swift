import Foundation

@MainActor
final class DependencyContainer {
    let appState = AppState()
    let notchState = NotchState()
    let settingsState = SettingsState()
    let clipboardState = ClipboardState()
    let copyStackState = CopyStackState()
    let mediaState = MediaState()
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
            mediaState: mediaState,
            settingsState: settingsState,
            localStore: localStore
        )
        settingsState.onPauseClipboardMonitoringChanged = { [weak clipboardMonitor] isPaused in
            clipboardMonitor?.setPaused(isPaused)
        }
        clipboardMonitor.setPaused(settingsState.pauseClipboardMonitoring)
    }

    func start() {
        clipboardState.items = localStore.fetchItems()
        clipboardState.boards = localStore.fetchBoards()
        clipboardState.boardNamesByItemID = localStore.fetchBoardNamesByItemID()
        clipboardState.reconcileSelection()
        clipboardMonitor.onItemsChanged = { [weak self] items in
            Task { @MainActor in
                guard let self else { return }
                if let boardID = self.clipboardState.selectedBoardID {
                    self.clipboardState.items = self.localStore.fetchItems(boardID: boardID)
                } else {
                    self.clipboardState.items = items
                }
                self.clipboardState.boardNamesByItemID = self.localStore.fetchBoardNamesByItemID()
                self.clipboardState.reconcileSelection()
            }
        }
        clipboardMonitor.start()
        mediaState.start()
        shortcutManager.registerDefaultShortcut { [weak self] in
            Task { @MainActor in self?.notchController.toggleExpanded() }
        }
    }

    func stop() {
        clipboardMonitor.stop()
        mediaState.stop()
        shortcutManager.unregister()
        notchController.stop()
    }

    func clearClipboardHistory() {
        localStore.clearItems()
        clipboardState.items = localStore.fetchItems(boardID: clipboardState.selectedBoardID)
        clipboardState.boardNamesByItemID = [:]
        clipboardState.reconcileSelection()
    }

    func showCompactNotch() {
        notchController.showCompact()
    }

    func hideNotchForSettings() {
        notchController.hideForSettings()
    }
}
