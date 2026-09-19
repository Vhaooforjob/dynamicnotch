import SwiftUI

struct SettingsView: View {
    @ObservedObject var state: SettingsState

    var body: some View {
        TabView {
            Form {
                Toggle("settings.launchAtLogin", isOn: $state.launchAtLogin)
            }
            .tabItem { Label("settings.general", systemImage: "gear") }

            Form {
                Toggle("settings.pauseClipboard", isOn: $state.pauseClipboardMonitoring)
                Button("settings.clearClipboard") {}
            }
            .tabItem { Label("settings.clipboard", systemImage: "square.on.square") }

            Form {
                Toggle("settings.cloudSync", isOn: $state.cloudSyncEnabled)
                    .disabled(!FeatureFlags.cloudSync)
            }
            .tabItem { Label("settings.sync", systemImage: "arrow.triangle.2.circlepath") }

            Form {
                Text("settings.privacyBody")
                    .foregroundStyle(.secondary)
            }
            .tabItem { Label("settings.privacy", systemImage: "hand.raised") }
        }
        .padding()
    }
}
