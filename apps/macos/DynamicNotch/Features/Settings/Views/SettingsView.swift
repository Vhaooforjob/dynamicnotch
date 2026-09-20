import SwiftUI

struct SettingsView: View {
    @ObservedObject var state: SettingsState
    let onClearClipboard: () -> Void

    var body: some View {
        TabView {
            Form {
                Toggle(state.text("launchAtLogin"), isOn: $state.launchAtLogin)
                Picker(state.text("appearance"), selection: $state.appearanceMode) {
                    Text(state.text("system")).tag(AppearanceMode.system)
                    Text(state.text("light")).tag(AppearanceMode.light)
                    Text(state.text("dark")).tag(AppearanceMode.dark)
                }
                .pickerStyle(.segmented)
                Picker(state.text("language"), selection: $state.appLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.label).tag(language)
                    }
                }
                .pickerStyle(.segmented)
            }
            .tabItem { Label(state.text("settingsGeneral"), systemImage: "gear") }

            Form {
                Toggle(state.text("pauseClipboard"), isOn: $state.pauseClipboardMonitoring)
                Button(state.text("clearClipboard"), role: .destructive) {
                    onClearClipboard()
                }
            }
            .tabItem { Label(state.text("settingsClipboard"), systemImage: "square.on.square") }

            Form {
                Toggle(state.text("cloudSync"), isOn: $state.cloudSyncEnabled)
                    .disabled(!FeatureFlags.cloudSync)
            }
            .tabItem { Label(state.text("settingsSync"), systemImage: "arrow.triangle.2.circlepath") }

            Form {
                Text(state.text("privacyBody"))
                    .foregroundStyle(.secondary)
            }
            .tabItem { Label(state.text("settingsPrivacy"), systemImage: "hand.raised") }
        }
        .padding()
    }
}
