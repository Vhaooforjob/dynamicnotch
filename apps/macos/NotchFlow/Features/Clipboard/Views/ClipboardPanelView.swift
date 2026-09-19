import SwiftUI

struct ClipboardPanelView: View {
    @ObservedObject var state: ClipboardState
    @ObservedObject var copyStackState: CopyStackState
    let localStore: ClipboardLocalStore

    var body: some View {
        VStack(spacing: NFSpacing.md) {
            NFSearchField(text: $state.query, placeholder: "clipboard.search")
            HStack {
                filter("All", nil)
                filter("Text", .text)
                filter("Link", .url)
                filter("Code", .code)
                Spacer()
                Toggle("Stack", isOn: Binding(
                    get: { copyStackState.isEnabled },
                    set: { copyStackState.setEnabled($0) }
                ))
                .toggleStyle(.switch)
                .font(NFTypography.caption)
            }
            HStack(spacing: NFSpacing.sm) {
                Button {
                    state.selectedBoardID = nil
                    state.items = localStore.fetchItems()
                } label: {
                    NFPill(title: "All", isSelected: state.selectedBoardID == nil)
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
                .accessibilityLabel("clipboard.newBoard")
                Spacer()
            }
            ScrollView {
                LazyVStack(spacing: NFSpacing.sm) {
                    if state.filteredItems.isEmpty {
                        NFCard {
                            Text("clipboard.empty")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    } else {
                        ForEach(state.filteredItems) { item in
                            ClipboardRow(item: item)
                                .contextMenu {
                                    Button("clipboard.copy") {
                                        ClipboardLocalStore.copyToPasteboard(item)
                                    }
                                    if let board = state.selectedBoard ?? state.boards.first {
                                        Button("clipboard.addToBoard") {
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
        "Board \(state.boards.count + 1)"
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
