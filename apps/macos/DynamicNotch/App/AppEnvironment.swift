import Foundation

enum FeatureFlags {
    static let scrollingScreenshot = false
    static let smartCapture = false
    static let cloudSync = false
    static let advancedTranslation = false
    static let agentApproval = false
    static let lyrics = false
    static let audioMixer = true
}

@MainActor
final class AppState: ObservableObject {
    @Published var isReady = true
}
