import XCTest
@testable import DynamicNotch

final class ClipboardSearchTests: XCTestCase {
    func testFilterByTypeToken() {
        let items = [item("https://example.com", .url), item("let value = 1", .code)]
        XCTAssertEqual(ClipboardSearchEngine.filter(items: items, query: "@link", selectedType: nil).count, 1)
        XCTAssertEqual(ClipboardSearchEngine.filter(items: items, query: "@code", selectedType: nil).first?.type, .code)
    }

    func testCombinesTypeApplicationBoardAndTextFilters() {
        let safariItem = item("Swift concurrency guide", .url, sourceApplication: "Safari")
        let notesItem = item("Swift meeting notes", .text, sourceApplication: "Notes")
        let boardNames = [safariItem.id: ["Development"], notesItem.id: ["Work"]]

        let result = ClipboardSearchEngine.filter(
            items: [safariItem, notesItem],
            query: "@link @app:saf @board:develop swift",
            selectedType: nil,
            boardNamesByItemID: boardNames
        )

        XCTAssertEqual(result.map(\.id), [safariItem.id])
    }

    func testTypeTokensAreCombinedAsAlternatives() {
        let items = [item("URL", .url), item("snippet", .code), item("note", .text)]
        let result = ClipboardSearchEngine.filter(
            items: items,
            query: "@link @code",
            selectedType: nil
        )

        XCTAssertEqual(Set(result.map(\.type)), [.url, .code])
    }

    private func item(
        _ text: String,
        _ type: ClipboardItemType,
        sourceApplication: String = "Safari"
    ) -> ClipboardItem {
        ClipboardItem(id: UUID(), type: type, plainText: text, richText: nil, fileURL: nil, imagePath: nil, sourceApplication: sourceApplication, sourceBundleIdentifier: nil, createdAt: Date(), updatedAt: Date(), isFavorite: false, boardID: nil, contentHash: text, metadata: [:])
    }
}
