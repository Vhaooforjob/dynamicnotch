import XCTest
@testable import DynamicNotch

@MainActor
final class SettingsStateTests: XCTestCase {
    func testPreferencesPersistAcrossInstances() {
        let defaults = makeDefaults()
        let state = SettingsState(userDefaults: defaults)

        state.showInMenuBar = false
        state.startMinimized = true
        state.appearanceMode = .light
        state.appLanguage = .vietnamese
        state.pauseClipboardMonitoring = true

        let restored = SettingsState(userDefaults: defaults)
        XCTAssertFalse(restored.showInMenuBar)
        XCTAssertTrue(restored.startMinimized)
        XCTAssertEqual(restored.appearanceMode, .light)
        XCTAssertEqual(restored.appLanguage, .vietnamese)
        XCTAssertTrue(restored.pauseClipboardMonitoring)
    }

    func testLaunchAtLoginSynchronizationDoesNotRepeatSystemUpdate() {
        let state = SettingsState(userDefaults: makeDefaults())
        var requestedValues: [Bool] = []
        state.onLaunchAtLoginChanged = { requestedValues.append($0) }

        state.synchronizeLaunchAtLogin(true)
        XCTAssertTrue(requestedValues.isEmpty)

        state.launchAtLogin = false
        XCTAssertEqual(requestedValues, [false])
    }

    private func makeDefaults() -> UserDefaults {
        let suiteName = "SettingsStateTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
