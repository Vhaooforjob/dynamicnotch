import Foundation

@MainActor
final class SettingsState: ObservableObject {
    @Published var launchAtLogin = false
    @Published var pauseClipboardMonitoring = false
    @Published var cloudSyncEnabled = false
}
