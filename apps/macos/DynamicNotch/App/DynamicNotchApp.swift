import SwiftUI

@main
struct DynamicNotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(
                state: appDelegate.container.settingsState,
                onClearClipboard: appDelegate.container.clearClipboardHistory
            )
                .preferredColorScheme(appDelegate.container.settingsState.appearanceMode.colorScheme)
                .frame(width: 680, height: 520)
        }
    }
}
