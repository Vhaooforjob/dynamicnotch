import SwiftUI

struct ClipboardPanelView: View {
    @ObservedObject var state: ClipboardState
    @ObservedObject var copyStackState: CopyStackState

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
