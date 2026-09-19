import SwiftUI

struct NFCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(NFSpacing.md)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: NFRadius.md, style: .continuous))
    }
}

struct NFPill: View {
    let title: String
    let isSelected: Bool

    var body: some View {
        Text(title)
            .font(NFTypography.caption)
            .padding(.horizontal, NFSpacing.md)
            .padding(.vertical, NFSpacing.xs)
            .background(isSelected ? Color.accentColor.opacity(0.22) : Color.white.opacity(0.08), in: Capsule())
            .accessibilityLabel(title)
    }
}

struct NFSearchField: View {
    @Binding var text: String
    let placeholder: LocalizedStringKey

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, NFSpacing.md)
        .padding(.vertical, NFSpacing.sm)
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: NFRadius.sm, style: .continuous))
    }
}
