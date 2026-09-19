import XCTest
@testable import NotchFlow

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
            sourceBundleIdentifier: "app.notchflow.tests",
            createdAt: createdAt,
            updatedAt: createdAt,
            isFavorite: false,
            boardID: nil,
            contentHash: ClipboardLocalStore.hash(text),
            metadata: [:]
        )
    }
}
