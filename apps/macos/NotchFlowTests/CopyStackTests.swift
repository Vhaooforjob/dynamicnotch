import XCTest
@testable import NotchFlow

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

    private func makeItem(_ text: String) -> ClipboardItem {
        ClipboardItem(id: UUID(), type: .text, plainText: text, richText: nil, fileURL: nil, imagePath: nil, sourceApplication: nil, sourceBundleIdentifier: nil, createdAt: Date(), updatedAt: Date(), isFavorite: false, boardID: nil, contentHash: text, metadata: [:])
    }
}
