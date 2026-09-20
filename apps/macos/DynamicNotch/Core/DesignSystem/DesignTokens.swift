import SwiftUI

enum NFSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
}

enum NFRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 22
}

enum NFTypography {
    static let caption = Font.system(size: 11, weight: .medium)
    static let body = Font.system(size: 13, weight: .medium)
    static let title = Font.system(size: 16, weight: .semibold)
}

enum NFAnimation {
    static let panel = Animation.interpolatingSpring(stiffness: 260, damping: 28)
    static let content = Animation.easeOut(duration: 0.18)
}

enum NFLayout {
    static let compactWidth: CGFloat = 280
    static let expandedWidth: CGFloat = 720
    static let compactHeight: CGFloat = 43
    static let quickPanelHeight: CGFloat = 238
    static let detailPanelHeight: CGFloat = 560
}

enum NFTheme {
    static let lightBackground = Color.white
    static let darkBackground = Color(red: 17 / 255, green: 18 / 255, blue: 23 / 255)
    static let accent = Color(red: 108 / 255, green: 99 / 255, blue: 255 / 255)
    static let accentBlue = Color(red: 64 / 255, green: 140 / 255, blue: 255 / 255)
    static let success = Color(red: 52 / 255, green: 199 / 255, blue: 89 / 255)
    static let warning = Color(red: 255 / 255, green: 159 / 255, blue: 10 / 255)
    static let danger = Color(red: 255 / 255, green: 69 / 255, blue: 58 / 255)
}

enum NFShadow {
    static let panel = Color.black.opacity(0.24)
    static let subtle = Color.black.opacity(0.12)
}
