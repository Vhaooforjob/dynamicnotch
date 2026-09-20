import SwiftUI

struct ClipboardPanelView: View {
    @ObservedObject var state: ClipboardState
    @ObservedObject var copyStackState: CopyStackState
    @ObservedObject var settingsState: SettingsState
    let localStore: ClipboardLocalStore
    let onBack: () -> Void
    @State private var boardBeingRenamed: Board?
    @State private var boardNameDraft = ""
    @State private var boardBeingDeleted: Board?

    var body: some View {
        VStack(spacing: NFSpacing.md) {
            NFSearchField(
                text: $state.query,
                placeholder: settingsState.text("searchClipboard"),
                autoFocus: true
            )
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
                VStack(spacing: NFSpacing.sm) {
                    HStack(spacing: NFSpacing.sm) {
                        Label("\(copyStackState.items.count)", systemImage: "tray.and.arrow.down")
                            .font(NFTypography.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button(settingsState.text("copyNext")) {
                            copyNextStackItem()
                        }
                        .buttonStyle(.plain)
                        .focusable(false)
                        .disabled(copyStackState.items.isEmpty)
                        Button(settingsState.text("clearStack")) {
                            copyStackState.clear()
                        }
                        .buttonStyle(.plain)
                        .focusable(false)
                        .disabled(copyStackState.items.isEmpty)
                    }
                    if !copyStackState.items.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: NFSpacing.sm) {
                                ForEach(Array(copyStackState.items.enumerated()), id: \.element.id) { index, item in
                                    HStack(spacing: NFSpacing.xs) {
                                        Text(item.previewText)
                                            .lineLimit(1)
                                            .frame(maxWidth: 120)
                                        Button {
                                            copyStackState.remove(item)
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                        }
                                        .buttonStyle(.plain)
                                        .accessibilityLabel(settingsState.text("removeFromStack"))
                                    }
                                    .font(NFTypography.caption)
                                    .padding(.horizontal, NFSpacing.sm)
                                    .padding(.vertical, NFSpacing.xs)
                                    .background(Color.primary.opacity(0.06), in: Capsule())
                                    .contextMenu {
                                        Button(settingsState.text("moveEarlier")) {
                                            copyStackState.move(from: index, to: index - 1)
                                        }
                                        .disabled(index == 0)
                                        Button(settingsState.text("moveLater")) {
                                            copyStackState.move(from: index, to: index + 1)
                                        }
                                        .disabled(index == copyStackState.items.count - 1)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: NFSpacing.sm) {
                    Button {
                        state.selectedBoardID = nil
                        refreshState()
                    } label: {
                        NFPill(title: settingsState.text("all"), isSelected: state.selectedBoardID == nil)
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    ForEach(state.boards) { board in
                        Button {
                            state.selectedBoardID = board.id
                            refreshState()
                        } label: {
                            NFPill(title: board.name, isSelected: state.selectedBoardID == board.id)
                        }
                        .buttonStyle(.plain)
                        .focusable(false)
                        .contextMenu {
                            Button(settingsState.text("rename")) {
                                beginRenaming(board)
                            }
                            Button(settingsState.text("moveLeft")) {
                                moveBoard(board, by: -1)
                            }
                            .disabled(board.id == state.boards.first?.id)
                            Button(settingsState.text("moveRight")) {
                                moveBoard(board, by: 1)
                            }
                            .disabled(board.id == state.boards.last?.id)
                            Button(settingsState.text("delete"), role: .destructive) {
                                boardBeingDeleted = board
                            }
                        }
                    }
                    Button {
                        let board = localStore.createBoard(named: defaultBoardName())
                        state.selectedBoardID = board.id
                        refreshState()
                        beginRenaming(board)
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                    .buttonStyle(.plain)
                    .focusable(false)
                    .accessibilityLabel(settingsState.text("newBoard"))
                    if let selectedBoard = state.selectedBoard {
                        Button {
                            beginRenaming(selectedBoard)
                        } label: {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(.plain)
                        .focusable(false)
                        .accessibilityLabel(settingsState.text("renameBoard"))

                        Button(role: .destructive) {
                            boardBeingDeleted = selectedBoard
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.plain)
                        .focusable(false)
                        .accessibilityLabel(settingsState.text("deleteBoard"))
                    }
                    Spacer(minLength: 0)
                }
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
                            ClipboardRow(
                                item: item,
                                isSelected: state.selectedItemID == item.id,
                                onSelect: { handlePrimaryAction(for: item) },
                                onCopy: { ClipboardLocalStore.copyToPasteboard(item) },
                                onFavorite: { toggleFavorite(item) },
                                copyLabel: settingsState.text("copy"),
                                favoriteLabel: settingsState.text(item.isFavorite ? "unfavorite" : "favorite")
                            )
                            .contextMenu {
                                Button(settingsState.text("copy")) {
                                    ClipboardLocalStore.copyToPasteboard(item)
                                }
                                Button(settingsState.text("addToStack")) {
                                    copyStackState.setEnabled(true)
                                    copyStackState.push(item)
                                }
                                if !state.boards.isEmpty {
                                    Menu(settingsState.text("addToBoard")) {
                                        ForEach(state.boards) { board in
                                            Button(board.name) {
                                                localStore.addItem(item, to: board)
                                                refreshState()
                                            }
                                        }
                                    }
                                }
                                if let selectedBoard = state.selectedBoard {
                                    Button(settingsState.text("removeFromBoard"), role: .destructive) {
                                        localStore.removeItem(item, from: selectedBoard)
                                        refreshState()
                                    }
                                }
                                Button(settingsState.text(item.isFavorite ? "unfavorite" : "favorite")) {
                                    toggleFavorite(item)
                                }
                                Button(settingsState.text("deleteItem"), role: .destructive) {
                                    localStore.deleteItem(item)
                                    refreshState()
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
        .onAppear {
            refreshState()
        }
        .onChange(of: state.filteredItems.map(\.id)) {
            state.reconcileSelection()
        }
        .onKeyPress(.upArrow) {
            state.selectPreviousItem()
            return .handled
        }
        .onKeyPress(.downArrow) {
            state.selectNextItem()
            return .handled
        }
        .onKeyPress(.return) {
            activateSelectedItem()
            return .handled
        }
        .onExitCommand(perform: onBack)
    }

    private func filter(_ title: String, _ type: ClipboardItemType?) -> some View {
        Button {
            state.selectedType = type
        } label: {
            NFPill(title: title, isSelected: state.selectedType == type)
        }
        .buttonStyle(.plain)
        .focusable(false)
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
        refreshState()
        boardBeingRenamed = nil
    }

    private func deleteBoard() {
        guard let board = boardBeingDeleted else { return }
        localStore.deleteBoard(board)
        if state.selectedBoardID == board.id {
            state.selectedBoardID = nil
        }
        refreshState()
        boardBeingDeleted = nil
    }

    private func moveBoard(_ board: Board, by offset: Int) {
        localStore.moveBoard(board, by: offset)
        refreshState()
    }

    private func toggleFavorite(_ item: ClipboardItem) {
        localStore.setFavorite(!item.isFavorite, for: item)
        refreshState()
    }

    private func activateSelectedItem() {
        guard let selectedItemID = state.selectedItemID,
              let item = state.filteredItems.first(where: { $0.id == selectedItemID })
        else { return }
        handlePrimaryAction(for: item)
    }

    private func refreshState() {
        state.boards = localStore.fetchBoards()
        state.items = localStore.fetchItems(boardID: state.selectedBoardID)
        state.boardNamesByItemID = localStore.fetchBoardNamesByItemID()
        state.reconcileSelection()
    }
}

struct ClipboardRow: View {
    let item: ClipboardItem
    let isSelected: Bool
    let onSelect: () -> Void
    let onCopy: () -> Void
    let onFavorite: () -> Void
    let copyLabel: String
    let favoriteLabel: String

    var body: some View {
        NFCard(isSelected: isSelected) {
            HStack(spacing: NFSpacing.md) {
                Button(action: onSelect) {
                    VStack(alignment: .leading, spacing: NFSpacing.xs) {
                        HStack {
                            Text(item.sourceApplication ?? "Unknown")
                                .font(NFTypography.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(item.type.rawValue)
                                .font(NFTypography.caption)
                                .foregroundStyle(.tertiary)
                        }
                        Text(item.previewText)
                            .font(NFTypography.body)
                            .lineLimit(2)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .focusable(false)

                Button(action: onCopy) {
                    Image(systemName: "doc.on.doc")
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .focusable(false)
                .accessibilityLabel(copyLabel)

                Button(action: onFavorite) {
                    Image(systemName: item.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(item.isFavorite ? NFTheme.warning : Color.secondary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .focusable(false)
                .accessibilityLabel(favoriteLabel)
            }
        }
        .accessibilityLabel(item.previewText)
    }
}
