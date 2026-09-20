import XCTest
@testable import DynamicNotch

@MainActor
final class CopyStackTests: XCTestCase {
    func testCopyStackPopsFIFO() {
        let state = CopyStackState()
        state.setEnabled(true)
        let first = makeItem("A")
        let second = makeItem("B")
        state.push(first)
        state.push(second)
        XCTAssertEqual(state.popNext()?.plainText, "A")
        XCTAssertEqual(state.popNext()?.plainText, "B")
    }

    func testCopyStackCanPauseReorderAndRemoveItems() {
        let state = CopyStackState()
        let first = makeItem("A")
        let second = makeItem("B")
        state.setEnabled(true)
        state.push(first)
        state.push(second)

        state.move(from: 1, to: 0)
        XCTAssertEqual(state.items.map(\.plainText), ["B", "A"])

        state.setEnabled(false)
        state.push(makeItem("Ignored while paused"))
        XCTAssertEqual(state.items.count, 2)

        state.remove(first)
        XCTAssertEqual(state.items.map(\.plainText), ["B"])
    }

    private func makeItem(_ text: String) -> ClipboardItem {
        ClipboardItem(id: UUID(), type: .text, plainText: text, richText: nil, fileURL: nil, imagePath: nil, sourceApplication: nil, sourceBundleIdentifier: nil, createdAt: Date(), updatedAt: Date(), isFavorite: false, boardID: nil, contentHash: text, metadata: [:])
    }
}
