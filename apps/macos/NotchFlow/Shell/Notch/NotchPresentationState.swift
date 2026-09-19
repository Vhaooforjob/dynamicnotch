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

@MainActor
final class NotchState: ObservableObject {
    @Published var presentation: NotchPresentationState = .idle
    @Published var isPinned = false
}
