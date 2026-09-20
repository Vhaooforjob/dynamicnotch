import Foundation
import SwiftUI

enum AppearanceMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            nil
        case .light:
            .light
        case .dark:
            .dark
        }
    }
}

@MainActor
final class SettingsState: ObservableObject {
    @Published var launchAtLogin = false
    @Published var showInMenuBar = true
    @Published var startMinimized = false
    @Published var appearanceMode: AppearanceMode = .system {
        didSet {
            userDefaults.set(appearanceMode.rawValue, forKey: Self.appearanceModeKey)
        }
    }
    @Published var appLanguage: AppLanguage = .english {
        didSet {
            userDefaults.set(appLanguage.rawValue, forKey: Self.appLanguageKey)
        }
    }
    @Published var pauseClipboardMonitoring = false {
        didSet {
            onPauseClipboardMonitoringChanged?(pauseClipboardMonitoring)
        }
    }
    @Published var cloudSyncEnabled = false

    var onPauseClipboardMonitoringChanged: ((Bool) -> Void)?

    private let userDefaults: UserDefaults
    private static let appearanceModeKey = "settings.appearanceMode"
    private static let appLanguageKey = "settings.appLanguage"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let rawAppearance = userDefaults.string(forKey: Self.appearanceModeKey),
           let savedAppearance = AppearanceMode(rawValue: rawAppearance) {
            appearanceMode = savedAppearance
        }
        if let rawLanguage = userDefaults.string(forKey: Self.appLanguageKey),
           let savedLanguage = AppLanguage(rawValue: rawLanguage) {
            appLanguage = savedLanguage
        }
    }

    func text(_ key: String) -> String {
        AppStrings.text(key, language: appLanguage)
    }
}
