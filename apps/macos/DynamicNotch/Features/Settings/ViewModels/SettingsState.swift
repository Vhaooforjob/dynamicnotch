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
    @Published var launchAtLogin = false {
        didSet {
            userDefaults.set(launchAtLogin, forKey: Self.launchAtLoginKey)
            guard !isUpdatingLaunchAtLogin else { return }
            onLaunchAtLoginChanged?(launchAtLogin)
        }
    }
    @Published var showInMenuBar = true {
        didSet {
            userDefaults.set(showInMenuBar, forKey: Self.showInMenuBarKey)
            onShowInMenuBarChanged?(showInMenuBar)
        }
    }
    @Published var startMinimized = false {
        didSet {
            userDefaults.set(startMinimized, forKey: Self.startMinimizedKey)
        }
    }
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
            userDefaults.set(pauseClipboardMonitoring, forKey: Self.pauseClipboardMonitoringKey)
            onPauseClipboardMonitoringChanged?(pauseClipboardMonitoring)
        }
    }
    @Published var cloudSyncEnabled = false

    var onLaunchAtLoginChanged: ((Bool) -> Void)?
    var onShowInMenuBarChanged: ((Bool) -> Void)?
    var onPauseClipboardMonitoringChanged: ((Bool) -> Void)?

    private let userDefaults: UserDefaults
    private var isUpdatingLaunchAtLogin = false
    private static let launchAtLoginKey = "settings.launchAtLogin"
    private static let showInMenuBarKey = "settings.showInMenuBar"
    private static let startMinimizedKey = "settings.startMinimized"
    private static let appearanceModeKey = "settings.appearanceMode"
    private static let appLanguageKey = "settings.appLanguage"
    private static let pauseClipboardMonitoringKey = "settings.pauseClipboardMonitoring"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        launchAtLogin = userDefaults.bool(forKey: Self.launchAtLoginKey)
        showInMenuBar = userDefaults.object(forKey: Self.showInMenuBarKey) as? Bool ?? true
        startMinimized = userDefaults.bool(forKey: Self.startMinimizedKey)
        pauseClipboardMonitoring = userDefaults.bool(forKey: Self.pauseClipboardMonitoringKey)
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

    func synchronizeLaunchAtLogin(_ enabled: Bool) {
        guard launchAtLogin != enabled else { return }
        isUpdatingLaunchAtLogin = true
        launchAtLogin = enabled
        isUpdatingLaunchAtLogin = false
    }
}
