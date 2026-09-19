import SwiftUI

@main
struct NotchFlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(state: appDelegate.container.settingsState)
                .frame(width: 680, height: 520)
        }
    }
}
