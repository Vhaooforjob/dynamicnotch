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
                .frame(width: 760, height: 520)
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                SettingsLink {
                    Text(appDelegate.container.settingsState.text("settingsShort"))
                }
            }
        }
    }
}
