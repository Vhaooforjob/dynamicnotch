import Foundation

enum ClipboardSearchEngine {
    static func filter(
        items: [ClipboardItem],
        query: String,
        selectedType: ClipboardItemType?,
        boardNamesByItemID: [UUID: [String]] = [:]
    ) -> [ClipboardItem] {
        let parsedQuery = ParsedQuery(query)
        return items.filter { item in
            if let selectedType, item.type != selectedType {
                return false
            }

            return parsedQuery.matches(
                item,
                boardNames: boardNamesByItemID[item.id] ?? []
            )
        }
    }
}

private struct ParsedQuery {
    private var types: Set<ClipboardItemType> = []
    private var applications: [String] = []
    private var boards: [String] = []
    private var terms: [String] = []

    init(_ query: String) {
        for token in query.split(whereSeparator: \Character.isWhitespace).map(String.init) {
            let normalized = Self.normalize(token)
            if let type = Self.type(for: normalized) {
                types.insert(type)
            } else if normalized.hasPrefix("@app:") {
                let application = String(normalized.dropFirst("@app:".count))
                if !application.isEmpty {
                    applications.append(application)
                }
            } else if normalized.hasPrefix("@board:") {
                let board = String(normalized.dropFirst("@board:".count))
                if !board.isEmpty {
                    boards.append(board)
                }
            } else if !normalized.isEmpty {
                terms.append(normalized)
            }
        }
    }

    func matches(_ item: ClipboardItem, boardNames: [String]) -> Bool {
        if !types.isEmpty, !types.contains(item.type) {
            return false
        }

        let application = Self.normalize(item.sourceApplication ?? "")
        if !applications.allSatisfy(application.contains) {
            return false
        }

        let normalizedBoards = boardNames.map(Self.normalize)
        if !boards.allSatisfy({ filter in normalizedBoards.contains(where: { $0.contains(filter) }) }) {
            return false
        }

        let searchableText = [
            item.previewText,
            item.sourceApplication ?? "",
            item.type.rawValue
        ]
            .map(Self.normalize)
            .joined(separator: " ")
        return terms.allSatisfy(searchableText.contains)
    }

    private static func type(for token: String) -> ClipboardItemType? {
        switch token {
        case "@text": .text
        case "@richtext": .richText
        case "@link", "@url": .url
        case "@image": .image
        case "@file": .file
        case "@color": .color
        case "@code": .code
        case "@unknown": .unknown
        default: nil
        }
    }

    private static func normalize(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}
