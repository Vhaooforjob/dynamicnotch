import Foundation

@MainActor
final class ClipboardState: ObservableObject {
    @Published var items: [ClipboardItem] = []
    @Published var boards: [Board] = []
    @Published var query = ""
    @Published var selectedType: ClipboardItemType?
    @Published var selectedBoardID: UUID?
    @Published var selectedItemID: UUID?
    @Published var boardNamesByItemID: [UUID: [String]] = [:]

    var filteredItems: [ClipboardItem] {
        ClipboardSearchEngine.filter(
            items: items,
            query: query,
            selectedType: selectedType,
            boardNamesByItemID: boardNamesByItemID
        )
    }

    var selectedBoard: Board? {
        guard let selectedBoardID else { return nil }
        return boards.first { $0.id == selectedBoardID }
    }

    func selectNextItem() {
        moveSelection(by: 1)
    }

    func selectPreviousItem() {
        moveSelection(by: -1)
    }

    func reconcileSelection() {
        let visibleIDs = filteredItems.map(\.id)
        guard !visibleIDs.isEmpty else {
            selectedItemID = nil
            return
        }
        if selectedItemID.map({ !visibleIDs.contains($0) }) ?? true {
            selectedItemID = visibleIDs[0]
        }
    }

    private func moveSelection(by offset: Int) {
        let visibleItems = filteredItems
        guard !visibleItems.isEmpty else {
            selectedItemID = nil
            return
        }
        guard let selectedItemID,
              let currentIndex = visibleItems.firstIndex(where: { $0.id == selectedItemID })
        else {
            self.selectedItemID = visibleItems[0].id
            return
        }
        let targetIndex = min(max(currentIndex + offset, 0), visibleItems.count - 1)
        self.selectedItemID = visibleItems[targetIndex].id
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

    func remove(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
    }

    func move(from sourceIndex: Int, to destinationIndex: Int) {
        guard items.indices.contains(sourceIndex),
              destinationIndex >= 0,
              destinationIndex < items.count,
              sourceIndex != destinationIndex
        else { return }

        let item = items.remove(at: sourceIndex)
        items.insert(item, at: destinationIndex)
    }
}
