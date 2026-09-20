import SwiftUI

struct NFCard<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let content: Content
    var isSelected = false

    init(isSelected: Bool = false, @ViewBuilder content: () -> Content) {
        self.isSelected = isSelected
        self.content = content()
    }

    var body: some View {
        content
            .padding(NFSpacing.md)
            .background(cardBackground, in: RoundedRectangle(cornerRadius: NFRadius.md, style: .continuous))
    }

    private var cardBackground: Color {
        if isSelected {
            return NFTheme.accent.opacity(colorScheme == .light ? 0.12 : 0.2)
        }
        return colorScheme == .light ? .white : Color.white.opacity(0.08)
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
            return NFTheme.accent.opacity(colorScheme == .light ? 0.18 : 0.24)
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
        colorScheme == .light ? .white : Color.white.opacity(0.08)
    }
}

struct NFIconTile: View {
    let systemName: String
    let color: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: NFRadius.sm, style: .continuous)
                .fill(color.opacity(0.18))
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color)
        }
        .frame(width: 34, height: 34)
    }
}

struct NFShortcutBadge: View {
    let title: String

    var body: some View {
        Text(title)
            .font(NFTypography.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, NFSpacing.sm)
            .padding(.vertical, NFSpacing.xs)
            .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: NFRadius.sm, style: .continuous))
    }
}
