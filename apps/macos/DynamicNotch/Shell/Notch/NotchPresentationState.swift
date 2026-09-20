import Foundation

enum NotchPresentationState: String {
    case hidden
    case idle
    case hovered
    case compact
    case expanded
    case pinned
    case activity
    case modal
}

enum NotchPanel: String, CaseIterable, Identifiable, Equatable {
    case quickPanel
    case clipboard
    case capture
    case media
    case calendar
    case agents

    var id: String { rawValue }
}

@MainActor
final class NotchState: ObservableObject {
    @Published var presentation: NotchPresentationState = .idle
    @Published var isPinned = false
    @Published var selectedPanel: NotchPanel = .quickPanel
}
