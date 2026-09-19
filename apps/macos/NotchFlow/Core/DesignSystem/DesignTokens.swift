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
    static let md: CGFloat = 14
    static let lg: CGFloat = 22
}

enum NFTypography {
    static let caption = Font.system(size: 11, weight: .medium)
    static let body = Font.system(size: 13, weight: .medium)
    static let title = Font.system(size: 16, weight: .semibold)
}

enum NFAnimation {
    static let panel = Animation.spring(response: 0.32, dampingFraction: 0.82)
}

enum NFLayout {
    static let compactWidth: CGFloat = 320
    static let expandedWidth: CGFloat = 560
    static let compactHeight: CGFloat = 44
    static let expandedHeight: CGFloat = 430
}
