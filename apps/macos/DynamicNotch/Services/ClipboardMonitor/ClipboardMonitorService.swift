import AppKit
import Foundation

@MainActor
final class ClipboardMonitorService {
    private let pasteboard = NSPasteboard.general
    private let store: ClipboardLocalStore
    private var timer: Timer?
    private var lastChangeCount: Int
    private var isPaused = false
    var onItemsChanged: (([ClipboardItem]) -> Void)?

    init(store: ClipboardLocalStore) {
        self.store = store
        lastChangeCount = pasteboard.changeCount
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.poll()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func setPaused(_ paused: Bool) {
        isPaused = paused
        if paused {
            lastChangeCount = pasteboard.changeCount
        }
    }

    private func poll() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount
        guard !isPaused else { return }
        guard let text = pasteboard.string(forType: .string), !text.isEmpty else { return }
        let item = ClipboardItem(
            id: UUID(),
            type: detectType(text),
            plainText: text,
            richText: nil,
            fileURL: nil,
            imagePath: nil,
            sourceApplication: NSWorkspace.shared.frontmostApplication?.localizedName,
            sourceBundleIdentifier: NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
            createdAt: Date(),
            updatedAt: Date(),
            isFavorite: false,
            boardID: nil,
            contentHash: ClipboardLocalStore.hash(text),
            metadata: [:]
        )
        store.insertIfNeeded(item)
        store.prune(using: .free)
        onItemsChanged?(store.fetchItems())
    }

    private func detectType(_ text: String) -> ClipboardItemType {
        if URL(string: text)?.scheme != nil { return .url }
        if text.contains("{") || text.contains("func ") || text.contains("const ") { return .code }
        return .text
    }
}
