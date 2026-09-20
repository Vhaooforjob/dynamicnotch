import AppKit
import CryptoKit
import Foundation
import SQLite3

final class ClipboardLocalStore {
    private var database: OpaquePointer?
    private let databaseURL: URL

    init(databaseURL: URL? = nil) {
        self.databaseURL = databaseURL ?? Self.defaultDatabaseURL()
        open(at: self.databaseURL)
        migrate()
    }

    deinit {
        sqlite3_close(database)
    }

    func insertIfNeeded(_ item: ClipboardItem) {
        guard findByHash(item.contentHash) == nil else { return }
        let sql = """
        INSERT INTO clipboard_items(id, type, plain_text, source_application, source_bundle_identifier, created_at, updated_at, is_favorite, content_hash)
        VALUES(?, ?, ?, ?, ?, ?, ?, ?, ?);
        """
        var statement: OpaquePointer?
        sqlite3_prepare_v2(database, sql, -1, &statement, nil)
        bind(statement, 1, item.id.uuidString)
        bind(statement, 2, item.type.rawValue)
        bind(statement, 3, item.plainText)
        bind(statement, 4, item.sourceApplication)
        bind(statement, 5, item.sourceBundleIdentifier)
        bind(statement, 6, Self.format(item.createdAt))
        bind(statement, 7, Self.format(item.updatedAt))
        sqlite3_bind_int(statement, 8, item.isFavorite ? 1 : 0)
        bind(statement, 9, item.contentHash)
        sqlite3_step(statement)
        sqlite3_finalize(statement)
    }

    static func copyToPasteboard(_ item: ClipboardItem) {
        guard let plainText = item.plainText else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(plainText, forType: .string)
    }

    func fetchItems(limit: Int = 200, boardID: UUID? = nil) -> [ClipboardItem] {
        let sql: String
        if boardID == nil {
            sql = """
            SELECT id, type, plain_text, source_application, source_bundle_identifier, created_at, updated_at, is_favorite, content_hash
            FROM clipboard_items
            ORDER BY is_favorite DESC, created_at DESC
            LIMIT ?;
            """
        } else {
            sql = """
            SELECT clipboard_items.id, type, plain_text, source_application, source_bundle_identifier, created_at, updated_at, is_favorite, content_hash
            FROM clipboard_items
            INNER JOIN board_items ON board_items.clipboard_item_id = clipboard_items.id
            WHERE board_items.board_id = ?
            ORDER BY clipboard_items.is_favorite DESC, board_items.sort_order ASC, clipboard_items.created_at DESC
            LIMIT ?;
            """
        }
        var statement: OpaquePointer?
        sqlite3_prepare_v2(database, sql, -1, &statement, nil)
        if let boardID {
            bind(statement, 1, boardID.uuidString)
            sqlite3_bind_int(statement, 2, Int32(limit))
        } else {
            sqlite3_bind_int(statement, 1, Int32(limit))
        }
        var items: [ClipboardItem] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard
                let idText = columnText(statement, 0),
                let id = UUID(uuidString: idText),
                let typeText = columnText(statement, 1),
                let type = ClipboardItemType(rawValue: typeText),
                let createdText = columnText(statement, 5),
                let createdAt = Self.date(from: createdText),
                let updatedText = columnText(statement, 6),
                let updatedAt = Self.date(from: updatedText),
                let hash = columnText(statement, 8)
            else { continue }
            items.append(ClipboardItem(
                id: id,
                type: type,
                plainText: columnText(statement, 2),
                richText: nil,
                fileURL: nil,
                imagePath: nil,
                sourceApplication: columnText(statement, 3),
                sourceBundleIdentifier: columnText(statement, 4),
                createdAt: createdAt,
                updatedAt: updatedAt,
                isFavorite: sqlite3_column_int(statement, 7) == 1,
                boardID: boardID,
                contentHash: hash,
                metadata: [:]
            ))
        }
        sqlite3_finalize(statement)
        return items
    }

    func createBoard(named name: String) -> Board {
        let now = Date()
        let board = Board(id: UUID(), name: name, sortOrder: nextBoardSortOrder(), createdAt: now, updatedAt: now)
        let sql = "INSERT INTO boards(id, name, sort_order, created_at, updated_at) VALUES(?, ?, ?, ?, ?);"
        var statement: OpaquePointer?
        sqlite3_prepare_v2(database, sql, -1, &statement, nil)
        bind(statement, 1, board.id.uuidString)
        bind(statement, 2, board.name)
        sqlite3_bind_int(statement, 3, Int32(board.sortOrder))
        bind(statement, 4, Self.format(board.createdAt))
        bind(statement, 5, Self.format(board.updatedAt))
        sqlite3_step(statement)
        sqlite3_finalize(statement)
        return board
    }

    func fetchBoards() -> [Board] {
        let sql = "SELECT id, name, sort_order, created_at, updated_at FROM boards ORDER BY sort_order ASC;"
        var statement: OpaquePointer?
        sqlite3_prepare_v2(database, sql, -1, &statement, nil)
        var boards: [Board] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            guard
                let idText = columnText(statement, 0),
                let id = UUID(uuidString: idText),
                let name = columnText(statement, 1),
                let createdText = columnText(statement, 3),
                let createdAt = Self.date(from: createdText),
                let updatedText = columnText(statement, 4),
                let updatedAt = Self.date(from: updatedText)
            else { continue }
            boards.append(Board(
                id: id,
                name: name,
                sortOrder: Int(sqlite3_column_int(statement, 2)),
                createdAt: createdAt,
                updatedAt: updatedAt
            ))
        }
        sqlite3_finalize(statement)
        return boards
    }

    func fetchBoardNamesByItemID() -> [UUID: [String]] {
        let sql = """
        SELECT board_items.clipboard_item_id, boards.name
        FROM board_items
        INNER JOIN boards ON boards.id = board_items.board_id
        INNER JOIN clipboard_items ON clipboard_items.id = board_items.clipboard_item_id
        ORDER BY boards.sort_order ASC;
        """
        var statement: OpaquePointer?
        sqlite3_prepare_v2(database, sql, -1, &statement, nil)
        defer { sqlite3_finalize(statement) }

        var result: [UUID: [String]] = [:]
        while sqlite3_step(statement) == SQLITE_ROW {
            guard let itemIDText = columnText(statement, 0),
                  let itemID = UUID(uuidString: itemIDText),
                  let boardName = columnText(statement, 1)
            else { continue }
            result[itemID, default: []].append(boardName)
        }
        return result
    }

    func addItem(_ item: ClipboardItem, to board: Board) {
        let sql = """
        INSERT OR IGNORE INTO board_items(board_id, clipboard_item_id, sort_order)
        SELECT ?, ?, ?
        WHERE EXISTS (SELECT 1 FROM boards WHERE id = ?)
          AND EXISTS (SELECT 1 FROM clipboard_items WHERE id = ?);
        """
        var statement: OpaquePointer?
        sqlite3_prepare_v2(database, sql, -1, &statement, nil)
        bind(statement, 1, board.id.uuidString)
        bind(statement, 2, item.id.uuidString)
        sqlite3_bind_int(statement, 3, Int32(nextBoardItemSortOrder(boardID: board.id)))
        bind(statement, 4, board.id.uuidString)
        bind(statement, 5, item.id.uuidString)
        sqlite3_step(statement)
        sqlite3_finalize(statement)
    }

    func removeItem(_ item: ClipboardItem, from board: Board) {
        var statement: OpaquePointer?
        sqlite3_prepare_v2(
            database,
            "DELETE FROM board_items WHERE board_id = ? AND clipboard_item_id = ?;",
            -1,
            &statement,
            nil
        )
        bind(statement, 1, board.id.uuidString)
        bind(statement, 2, item.id.uuidString)
        sqlite3_step(statement)
        sqlite3_finalize(statement)
    }

    func setFavorite(_ isFavorite: Bool, for item: ClipboardItem) {
        var statement: OpaquePointer?
        sqlite3_prepare_v2(database, "UPDATE clipboard_items SET is_favorite = ?, updated_at = ? WHERE id = ?;", -1, &statement, nil)
        sqlite3_bind_int(statement, 1, isFavorite ? 1 : 0)
        bind(statement, 2, Self.format(Date()))
        bind(statement, 3, item.id.uuidString)
        sqlite3_step(statement)
        sqlite3_finalize(statement)
    }

    func deleteItem(_ item: ClipboardItem) {
        sqlite3_exec(database, "BEGIN IMMEDIATE TRANSACTION;", nil, nil, nil)
        var statement: OpaquePointer?
        sqlite3_prepare_v2(database, "DELETE FROM board_items WHERE clipboard_item_id = ?;", -1, &statement, nil)
        bind(statement, 1, item.id.uuidString)
        sqlite3_step(statement)
        sqlite3_finalize(statement)

        sqlite3_prepare_v2(database, "DELETE FROM clipboard_items WHERE id = ?;", -1, &statement, nil)
        bind(statement, 1, item.id.uuidString)
        sqlite3_step(statement)
        sqlite3_finalize(statement)
        sqlite3_exec(database, "COMMIT;", nil, nil, nil)
    }

    func renameBoard(_ board: Board, to name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let sql = "UPDATE boards SET name = ?, updated_at = ? WHERE id = ?;"
        var statement: OpaquePointer?
        sqlite3_prepare_v2(database, sql, -1, &statement, nil)
        bind(statement, 1, trimmedName)
        bind(statement, 2, Self.format(Date()))
        bind(statement, 3, board.id.uuidString)
        sqlite3_step(statement)
        sqlite3_finalize(statement)
    }

    func deleteBoard(_ board: Board) {
        sqlite3_exec(database, "BEGIN IMMEDIATE TRANSACTION;", nil, nil, nil)
        var statement: OpaquePointer?
        sqlite3_prepare_v2(database, "DELETE FROM board_items WHERE board_id = ?;", -1, &statement, nil)
        bind(statement, 1, board.id.uuidString)
        sqlite3_step(statement)
        sqlite3_finalize(statement)

        sqlite3_prepare_v2(database, "DELETE FROM boards WHERE id = ?;", -1, &statement, nil)
        bind(statement, 1, board.id.uuidString)
        sqlite3_step(statement)
        sqlite3_finalize(statement)
        sqlite3_exec(database, "COMMIT;", nil, nil, nil)
    }

    func moveBoard(_ board: Board, by offset: Int) {
        var boards = fetchBoards()
        guard let sourceIndex = boards.firstIndex(where: { $0.id == board.id }) else { return }
        let destinationIndex = sourceIndex + offset
        guard boards.indices.contains(destinationIndex) else { return }

        boards.swapAt(sourceIndex, destinationIndex)
        sqlite3_exec(database, "BEGIN IMMEDIATE TRANSACTION;", nil, nil, nil)
        for (sortOrder, board) in boards.enumerated() {
            var statement: OpaquePointer?
            sqlite3_prepare_v2(database, "UPDATE boards SET sort_order = ?, updated_at = ? WHERE id = ?;", -1, &statement, nil)
            sqlite3_bind_int(statement, 1, Int32(sortOrder))
            bind(statement, 2, Self.format(Date()))
            bind(statement, 3, board.id.uuidString)
            sqlite3_step(statement)
            sqlite3_finalize(statement)
        }
        sqlite3_exec(database, "COMMIT;", nil, nil, nil)
    }

    func clearItems() {
        sqlite3_exec(database, "DELETE FROM board_items; DELETE FROM clipboard_items;", nil, nil, nil)
    }

    func prune(using policy: RetentionPolicy) {
        if let maxAgeHours = policy.maxAgeHours {
            let cutoff = Calendar.current.date(byAdding: .hour, value: -maxAgeHours, to: Date()) ?? Date()
            var statement: OpaquePointer?
            sqlite3_prepare_v2(database, "DELETE FROM clipboard_items WHERE is_favorite = 0 AND created_at < ?;", -1, &statement, nil)
            bind(statement, 1, Self.format(cutoff))
            sqlite3_step(statement)
            sqlite3_finalize(statement)
        }

        let sql = """
        DELETE FROM clipboard_items
        WHERE id IN (
          SELECT id FROM clipboard_items
          WHERE is_favorite = 0
          ORDER BY created_at DESC
          LIMIT -1 OFFSET ?
        );
        """
        var statement: OpaquePointer?
        sqlite3_prepare_v2(database, sql, -1, &statement, nil)
        sqlite3_bind_int(statement, 1, Int32(policy.maxItems))
        sqlite3_step(statement)
        sqlite3_finalize(statement)
        removeOrphanedBoardItems()
    }

    static func hash(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
    }

    private static func defaultDatabaseURL() -> URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DynamicNotch/database", isDirectory: true)
        let databaseURL = directory.appendingPathComponent("dynamicnotch.sqlite")
        migrateLegacyDatabaseIfNeeded(to: databaseURL)
        return databaseURL
    }

    private static func migrateLegacyDatabaseIfNeeded(to databaseURL: URL) {
        let legacyAppDirectory = ["Notch", "Flow"].joined()
        let legacyDatabaseName = "notch" + "flow.sqlite"
        let legacyURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(legacyAppDirectory)/database/\(legacyDatabaseName)")
        guard !FileManager.default.fileExists(atPath: databaseURL.path),
              FileManager.default.fileExists(atPath: legacyURL.path)
        else { return }

        try? FileManager.default.createDirectory(at: databaseURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? FileManager.default.copyItem(at: legacyURL, to: databaseURL)
    }

    private func open(at url: URL) {
        let directory = url.deletingLastPathComponent()
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        sqlite3_open(url.path, &database)
        sqlite3_exec(database, "PRAGMA foreign_keys = ON;", nil, nil, nil)
    }

    private func migrate() {
        sqlite3_exec(database, """
        CREATE TABLE IF NOT EXISTS clipboard_items(
          id TEXT PRIMARY KEY,
          type TEXT NOT NULL,
          plain_text TEXT,
          rich_text BLOB,
          file_url TEXT,
          image_path TEXT,
          source_application TEXT,
          source_bundle_identifier TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          is_favorite INTEGER NOT NULL DEFAULT 0,
          board_id TEXT,
          content_hash TEXT NOT NULL UNIQUE,
          metadata TEXT
        );
        CREATE INDEX IF NOT EXISTS clipboard_items_created_at_idx ON clipboard_items(created_at DESC);
        CREATE INDEX IF NOT EXISTS clipboard_items_type_idx ON clipboard_items(type);
        CREATE INDEX IF NOT EXISTS clipboard_items_source_bundle_idx ON clipboard_items(source_bundle_identifier);
        CREATE INDEX IF NOT EXISTS clipboard_items_content_hash_idx ON clipboard_items(content_hash);
        CREATE TABLE IF NOT EXISTS boards(id TEXT PRIMARY KEY, name TEXT NOT NULL, sort_order INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL, updated_at TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS board_items(
          board_id TEXT NOT NULL REFERENCES boards(id) ON DELETE CASCADE,
          clipboard_item_id TEXT NOT NULL REFERENCES clipboard_items(id) ON DELETE CASCADE,
          sort_order INTEGER NOT NULL DEFAULT 0,
          PRIMARY KEY(board_id, clipboard_item_id)
        );
        CREATE INDEX IF NOT EXISTS board_items_clipboard_item_idx ON board_items(clipboard_item_id);
        CREATE TABLE IF NOT EXISTS settings(key TEXT PRIMARY KEY, value TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS sync_metadata(key TEXT PRIMARY KEY, value TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS recent_searches(query TEXT PRIMARY KEY, created_at TEXT NOT NULL);
        CREATE TABLE IF NOT EXISTS agent_sessions(id TEXT PRIMARY KEY, provider TEXT NOT NULL, title TEXT NOT NULL, status TEXT NOT NULL, updated_at TEXT NOT NULL);
        """, nil, nil, nil)
        removeOrphanedBoardItems()
    }

    private func removeOrphanedBoardItems() {
        sqlite3_exec(database, """
        DELETE FROM board_items
        WHERE board_id NOT IN (SELECT id FROM boards)
           OR clipboard_item_id NOT IN (SELECT id FROM clipboard_items);
        """, nil, nil, nil)
    }

    private func findByHash(_ hash: String) -> String? {
        var statement: OpaquePointer?
        sqlite3_prepare_v2(database, "SELECT id FROM clipboard_items WHERE content_hash = ? LIMIT 1;", -1, &statement, nil)
        bind(statement, 1, hash)
        defer { sqlite3_finalize(statement) }
        return sqlite3_step(statement) == SQLITE_ROW ? columnText(statement, 0) : nil
    }

    private func nextBoardSortOrder() -> Int {
        scalarInt("SELECT COALESCE(MAX(sort_order), -1) + 1 FROM boards;")
    }

    private func nextBoardItemSortOrder(boardID: UUID) -> Int {
        var statement: OpaquePointer?
        sqlite3_prepare_v2(database, "SELECT COALESCE(MAX(sort_order), -1) + 1 FROM board_items WHERE board_id = ?;", -1, &statement, nil)
        bind(statement, 1, boardID.uuidString)
        defer { sqlite3_finalize(statement) }
        return sqlite3_step(statement) == SQLITE_ROW ? Int(sqlite3_column_int(statement, 0)) : 0
    }

    private func scalarInt(_ sql: String) -> Int {
        var statement: OpaquePointer?
        sqlite3_prepare_v2(database, sql, -1, &statement, nil)
        defer { sqlite3_finalize(statement) }
        return sqlite3_step(statement) == SQLITE_ROW ? Int(sqlite3_column_int(statement, 0)) : 0
    }

    private func bind(_ statement: OpaquePointer?, _ index: Int32, _ value: String?) {
        if let value {
            sqlite3_bind_text(statement, index, value, -1, SQLITE_TRANSIENT)
        } else {
            sqlite3_bind_null(statement, index)
        }
    }

    private func columnText(_ statement: OpaquePointer?, _ index: Int32) -> String? {
        guard let pointer = sqlite3_column_text(statement, index) else { return nil }
        return String(cString: pointer)
    }

    private static func format(_ date: Date) -> String {
        ISO8601DateFormatter().string(from: date)
    }

    private static func date(from string: String) -> Date? {
        ISO8601DateFormatter().date(from: string)
    }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
