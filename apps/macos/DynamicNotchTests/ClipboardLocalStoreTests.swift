import XCTest
@testable import DynamicNotch

final class ClipboardLocalStoreTests: XCTestCase {
    func testInsertDeduplicatesByContentHash() {
        let store = makeStore()
        store.insertIfNeeded(makeItem("same", createdAt: Date()))
        store.insertIfNeeded(makeItem("same", createdAt: Date()))

        XCTAssertEqual(store.fetchItems().count, 1)
    }

    func testBoardsAreSortedBySortOrder() {
        let store = makeStore()
        _ = store.createBoard(named: "Design")
        _ = store.createBoard(named: "Development")

        XCTAssertEqual(store.fetchBoards().map(\.name), ["Design", "Development"])
    }

    func testFetchItemsCanFilterByBoard() {
        let store = makeStore()
        let board = store.createBoard(named: "Design")
        let designItem = makeItem("palette", createdAt: Date())
        let otherItem = makeItem("invoice", createdAt: Date())
        store.insertIfNeeded(designItem)
        store.insertIfNeeded(otherItem)
        store.addItem(designItem, to: board)

        XCTAssertEqual(store.fetchItems(boardID: board.id).map(\.plainText), ["palette"])
        XCTAssertEqual(store.fetchItems().count, 2)
    }

    func testBoardsCanBeRenamedAndDeletedWithoutDeletingItems() {
        let store = makeStore()
        let board = store.createBoard(named: "Design")
        let item = makeItem("palette", createdAt: Date())
        store.insertIfNeeded(item)
        store.addItem(item, to: board)

        store.renameBoard(board, to: "Moodboard")
        XCTAssertEqual(store.fetchBoards().map(\.name), ["Moodboard"])

        store.deleteBoard(board)
        XCTAssertTrue(store.fetchBoards().isEmpty)
        XCTAssertTrue(store.fetchItems(boardID: board.id).isEmpty)
        XCTAssertEqual(store.fetchItems().map(\.plainText), ["palette"])
    }

    func testClearItemsRemovesHistoryAndBoardLinks() {
        let store = makeStore()
        let board = store.createBoard(named: "Design")
        let item = makeItem("palette", createdAt: Date())
        store.insertIfNeeded(item)
        store.addItem(item, to: board)

        store.clearItems()

        XCTAssertTrue(store.fetchItems().isEmpty)
        XCTAssertTrue(store.fetchItems(boardID: board.id).isEmpty)
        XCTAssertEqual(store.fetchBoards().map(\.name), ["Design"])
    }

    func testRetentionPrunesOldAndOverflowItems() {
        let store = makeStore()
        let old = Calendar.current.date(byAdding: .hour, value: -48, to: Date()) ?? Date()
        store.insertIfNeeded(makeItem("old", createdAt: old))
        store.insertIfNeeded(makeItem("new-1", createdAt: Date()))
        store.insertIfNeeded(makeItem("new-2", createdAt: Date()))

        store.prune(using: RetentionPolicy(maxAgeHours: 24, maxItems: 1))

        XCTAssertEqual(store.fetchItems().count, 1)
        XCTAssertTrue(store.fetchItems().first?.plainText?.hasPrefix("new") == true)
    }

    private func makeStore() -> ClipboardLocalStore {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("sqlite")
        return ClipboardLocalStore(databaseURL: url)
    }

    private func makeItem(_ text: String, createdAt: Date) -> ClipboardItem {
        ClipboardItem(
            id: UUID(),
            type: .text,
            plainText: text,
            richText: nil,
            fileURL: nil,
            imagePath: nil,
            sourceApplication: "Tests",
            sourceBundleIdentifier: "app.dynamicnotch.tests",
            createdAt: createdAt,
            updatedAt: createdAt,
            isFavorite: false,
            boardID: nil,
            contentHash: ClipboardLocalStore.hash(text),
            metadata: [:]
        )
    }
}
