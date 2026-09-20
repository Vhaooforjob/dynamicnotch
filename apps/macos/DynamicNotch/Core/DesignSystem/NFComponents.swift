import SwiftUI

struct NFCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(NFSpacing.md)
            .background(cardBackground, in: RoundedRectangle(cornerRadius: NFRadius.md, style: .continuous))
    }

    private var cardBackground: Color {
        colorScheme == .light ? Color.black.opacity(0.06) : Color.white.opacity(0.08)
    }
}

struct NFPill: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(NFTypography.caption)
            .padding(.horizontal, NFSpacing.md)
            .padding(.vertical, NFSpacing.xs)
            .background(pillBackground, in: Capsule())
            .accessibilityLabel(title)
    }

    private var pillBackground: Color {
        if isSelected {
            return Color.accentColor.opacity(colorScheme == .light ? 0.18 : 0.24)
        }
        return colorScheme == .light ? Color.black.opacity(0.06) : Color.white.opacity(0.08)
    }
}

struct NFSearchField: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, NFSpacing.md)
        .padding(.vertical, NFSpacing.sm)
        .background(searchBackground, in: RoundedRectangle(cornerRadius: NFRadius.sm, style: .continuous))
    }

    private var searchBackground: Color {
        colorScheme == .light ? Color.black.opacity(0.06) : Color.white.opacity(0.08)
    }
}
