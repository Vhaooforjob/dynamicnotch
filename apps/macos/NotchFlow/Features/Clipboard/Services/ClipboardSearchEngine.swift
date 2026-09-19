import Foundation

enum ClipboardSearchEngine {
    static func filter(items: [ClipboardItem], query: String, selectedType: ClipboardItemType?) -> [ClipboardItem] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return items.filter { item in
            if let selectedType, item.type != selectedType {
                return false
            }
            guard !trimmed.isEmpty else {
                return true
            }
            return matches(item: item, query: trimmed)
        }
    }

    private static func matches(item: ClipboardItem, query: String) -> Bool {
        let lower = query.lowercased()
        if lower.hasPrefix("@") {
            return matchesToken(item: item, token: lower)
        }
        return item.previewText.lowercased().contains(lower)
            || (item.sourceApplication?.lowercased().contains(lower) ?? false)
            || item.type.rawValue.lowercased().contains(lower)
    }

    private static func matchesToken(item: ClipboardItem, token: String) -> Bool {
        if token == "@link" {
            return item.type == .url
        }
        if token == "@text" || token == "@image" || token == "@file" || token == "@code" {
            return item.type.rawValue == String(token.dropFirst())
        }
        if token.hasPrefix("@app:") {
            let app = token.replacingOccurrences(of: "@app:", with: "")
            return item.sourceApplication?.lowercased().contains(app) ?? false
        }
        return false
    }
}
