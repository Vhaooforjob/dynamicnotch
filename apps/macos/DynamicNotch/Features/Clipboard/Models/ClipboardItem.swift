import Foundation

enum ClipboardItemType: String, CaseIterable, Codable {
    case text
    case richText
    case url
    case image
    case file
    case color
    case code
    case unknown

    var symbolName: String {
        switch self {
        case .text:
            "text.alignleft"
        case .richText:
            "textformat"
        case .url:
            "link"
        case .image:
            "photo"
        case .file:
            "doc"
        case .color:
            "paintpalette"
        case .code:
            "chevron.left.forwardslash.chevron.right"
        case .unknown:
            "questionmark.square"
        }
    }
}

struct ClipboardItem: Identifiable, Equatable, Codable {
    let id: UUID
    let type: ClipboardItemType
    let plainText: String?
    let richText: Data?
    let fileURL: URL?
    let imagePath: String?
    let sourceApplication: String?
    let sourceBundleIdentifier: String?
    let createdAt: Date
    var updatedAt: Date
    var isFavorite: Bool
    var boardID: UUID?
    let contentHash: String
    var metadata: [String: String]

    var previewText: String {
        plainText?.replacingOccurrences(of: "\n", with: " ") ?? type.rawValue
    }
}
