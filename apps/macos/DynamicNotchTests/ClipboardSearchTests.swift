import XCTest
@testable import DynamicNotch

final class ClipboardSearchTests: XCTestCase {
    func testFilterByTypeToken() {
        let items = [item("https://example.com", .url), item("let value = 1", .code)]
        XCTAssertEqual(ClipboardSearchEngine.filter(items: items, query: "@link", selectedType: nil).count, 1)
        XCTAssertEqual(ClipboardSearchEngine.filter(items: items, query: "@code", selectedType: nil).first?.type, .code)
    }

    private func item(_ text: String, _ type: ClipboardItemType) -> ClipboardItem {
        ClipboardItem(id: UUID(), type: type, plainText: text, richText: nil, fileURL: nil, imagePath: nil, sourceApplication: "Safari", sourceBundleIdentifier: nil, createdAt: Date(), updatedAt: Date(), isFavorite: false, boardID: nil, contentHash: text, metadata: [:])
    }
}
