import XCTest
@testable import DynamicNotch

@MainActor
final class ClipboardStateTests: XCTestCase {
    func testSelectionMovesWithinFilteredItemsAndReconciles() {
        let state = ClipboardState()
        let first = item("First")
        let second = item("Second")
        state.items = [first, second]

        state.reconcileSelection()
        XCTAssertEqual(state.selectedItemID, first.id)

        state.selectNextItem()
        XCTAssertEqual(state.selectedItemID, second.id)

        state.selectNextItem()
        XCTAssertEqual(state.selectedItemID, second.id)

        state.query = "First"
        state.reconcileSelection()
        XCTAssertEqual(state.selectedItemID, first.id)
    }

    private func item(_ text: String) -> ClipboardItem {
        ClipboardItem(
            id: UUID(),
            type: .text,
            plainText: text,
            richText: nil,
            fileURL: nil,
            imagePath: nil,
            sourceApplication: "Tests",
            sourceBundleIdentifier: nil,
            createdAt: Date(),
            updatedAt: Date(),
            isFavorite: false,
            boardID: nil,
            contentHash: text,
            metadata: [:]
        )
    }
}
