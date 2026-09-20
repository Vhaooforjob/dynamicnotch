import SwiftUI

struct ClipboardPanelView: View {
    @ObservedObject var state: ClipboardState
    @ObservedObject var copyStackState: CopyStackState
    @ObservedObject var settingsState: SettingsState
    let localStore: ClipboardLocalStore
    @State private var boardBeingRenamed: Board?
    @State private var boardNameDraft = ""
    @State private var boardBeingDeleted: Board?

    var body: some View {
        VStack(spacing: NFSpacing.md) {
            NFSearchField(text: $state.query, placeholder: settingsState.text("searchClipboard"))
            HStack {
                filter(settingsState.text("all"), nil)
                filter(settingsState.text("text"), .text)
                filter(settingsState.text("link"), .url)
                filter(settingsState.text("code"), .code)
                Spacer()
                Toggle(settingsState.text("stack"), isOn: Binding(
                    get: { copyStackState.isEnabled },
                    set: { copyStackState.setEnabled($0) }
                ))
                .toggleStyle(.switch)
                .font(NFTypography.caption)
            }
            if copyStackState.isEnabled {
                HStack(spacing: NFSpacing.sm) {
                    Label("\(copyStackState.items.count)", systemImage: "tray.and.arrow.down")
                        .font(NFTypography.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button(settingsState.text("copyNext")) {
                        copyNextStackItem()
                    }
                    .disabled(copyStackState.items.isEmpty)
                    Button(settingsState.text("clearStack")) {
                        copyStackState.clear()
                    }
                    .disabled(copyStackState.items.isEmpty)
                }
            }
            HStack(spacing: NFSpacing.sm) {
                Button {
                    state.selectedBoardID = nil
                    state.items = localStore.fetchItems()
                } label: {
                    NFPill(title: settingsState.text("all"), isSelected: state.selectedBoardID == nil)
                }
                .buttonStyle(.plain)
                ForEach(state.boards) { board in
                    Button {
                        state.selectedBoardID = board.id
                        state.items = localStore.fetchItems(boardID: board.id)
                    } label: {
                        NFPill(title: board.name, isSelected: state.selectedBoardID == board.id)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(settingsState.text("rename")) {
                            beginRenaming(board)
                        }
                        Button(settingsState.text("delete"), role: .destructive) {
                            boardBeingDeleted = board
                        }
                    }
                }
                Button {
                    let board = localStore.createBoard(named: defaultBoardName())
                    state.boards = localStore.fetchBoards()
                    state.selectedBoardID = board.id
                    state.items = localStore.fetchItems(boardID: board.id)
                } label: {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.plain)
                .accessibilityLabel(settingsState.text("newBoard"))
                if let selectedBoard = state.selectedBoard {
                    Button {
                        beginRenaming(selectedBoard)
                    } label: {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(settingsState.text("renameBoard"))

                    Button(role: .destructive) {
                        boardBeingDeleted = selectedBoard
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(settingsState.text("deleteBoard"))
                }
                Spacer()
            }
            ScrollView {
                LazyVStack(spacing: NFSpacing.sm) {
                    if state.filteredItems.isEmpty {
                        NFCard {
                            Text(settingsState.text("emptyClipboard"))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    } else {
                        ForEach(state.filteredItems) { item in
                            Button {
                                handlePrimaryAction(for: item)
                            } label: {
                                ClipboardRow(item: item)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(settingsState.text("copy")) {
                                    ClipboardLocalStore.copyToPasteboard(item)
                                }
                                Button(settingsState.text("addToStack")) {
                                    copyStackState.push(item)
                                }
                                if let board = state.selectedBoard ?? state.boards.first {
                                    Button(settingsState.text("addToBoard")) {
                                        localStore.addItem(item, to: board)
                                        if state.selectedBoardID == board.id {
                                            state.items = localStore.fetchItems(boardID: board.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .alert(settingsState.text("renameBoard"), isPresented: isRenamingBoard) {
            TextField(settingsState.text("boardName"), text: $boardNameDraft)
            Button(settingsState.text("save")) {
                renameBoard()
            }
            Button(settingsState.text("cancel"), role: .cancel) {
                boardBeingRenamed = nil
            }
        }
        .alert(settingsState.text("deleteBoardQuestion"), isPresented: isDeletingBoard) {
            Button(settingsState.text("delete"), role: .destructive) {
                deleteBoard()
            }
            Button(settingsState.text("cancel"), role: .cancel) {
                boardBeingDeleted = nil
            }
        } message: {
            Text(settingsState.text("deleteBoardMessage"))
        }
    }

    private func filter(_ title: String, _ type: ClipboardItemType?) -> some View {
        Button {
            state.selectedType = type
        } label: {
            NFPill(title: title, isSelected: state.selectedType == type)
        }
        .buttonStyle(.plain)
    }

    private func defaultBoardName() -> String {
        "\(settingsState.text("boardDefaultName")) \(state.boards.count + 1)"
    }

    private func handlePrimaryAction(for item: ClipboardItem) {
        if copyStackState.isEnabled {
            copyStackState.push(item)
        } else {
            ClipboardLocalStore.copyToPasteboard(item)
        }
    }

    private func copyNextStackItem() {
        guard let item = copyStackState.popNext() else { return }
        ClipboardLocalStore.copyToPasteboard(item)
    }

    private var isRenamingBoard: Binding<Bool> {
        Binding(
            get: { boardBeingRenamed != nil },
            set: { if !$0 { boardBeingRenamed = nil } }
        )
    }

    private var isDeletingBoard: Binding<Bool> {
        Binding(
            get: { boardBeingDeleted != nil },
            set: { if !$0 { boardBeingDeleted = nil } }
        )
    }

    private func beginRenaming(_ board: Board) {
        boardBeingRenamed = board
        boardNameDraft = board.name
    }

    private func renameBoard() {
        guard let board = boardBeingRenamed else { return }
        localStore.renameBoard(board, to: boardNameDraft)
        state.boards = localStore.fetchBoards()
        boardBeingRenamed = nil
    }

    private func deleteBoard() {
        guard let board = boardBeingDeleted else { return }
        localStore.deleteBoard(board)
        state.boards = localStore.fetchBoards()
        if state.selectedBoardID == board.id {
            state.selectedBoardID = nil
            state.items = localStore.fetchItems()
        }
        boardBeingDeleted = nil
    }
}

struct ClipboardRow: View {
    let item: ClipboardItem

    var body: some View {
        NFCard {
            VStack(alignment: .leading, spacing: NFSpacing.xs) {
                HStack {
                    Text(item.sourceApplication ?? "Unknown")
                        .font(NFTypography.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Image(systemName: "doc.on.doc")
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Copy")
                    Text(item.type.rawValue)
                        .font(NFTypography.caption)
                        .foregroundStyle(.tertiary)
                }
                Text(item.previewText)
                    .font(NFTypography.body)
                    .lineLimit(2)
            }
        }
        .accessibilityLabel("Clipboard item")
    }
}
