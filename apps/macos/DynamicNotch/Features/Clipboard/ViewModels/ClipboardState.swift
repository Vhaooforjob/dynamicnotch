import Foundation

@MainActor
final class ClipboardState: ObservableObject {
    @Published var items: [ClipboardItem] = []
    @Published var boards: [Board] = []
    @Published var query = ""
    @Published var selectedType: ClipboardItemType?
    @Published var selectedBoardID: UUID?

    var filteredItems: [ClipboardItem] {
        ClipboardSearchEngine.filter(items: items, query: query, selectedType: selectedType)
    }

    var selectedBoard: Board? {
        guard let selectedBoardID else { return nil }
        return boards.first { $0.id == selectedBoardID }
    }
}

@MainActor
final class CopyStackState: ObservableObject {
    @Published private(set) var isEnabled = false
    @Published private(set) var items: [ClipboardItem] = []

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }

    func push(_ item: ClipboardItem) {
        guard isEnabled else { return }
        items.append(item)
    }

    func popNext() -> ClipboardItem? {
        guard !items.isEmpty else { return nil }
        return items.removeFirst()
    }

    func clear() {
        items.removeAll()
    }
}
