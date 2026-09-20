import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case english
    case vietnamese

    var id: String { rawValue }

    var label: String {
        switch self {
        case .english:
            "English"
        case .vietnamese:
            "Tiếng Việt"
        }
    }
}

enum AppStrings {
    static func text(_ key: String, language: AppLanguage) -> String {
        switch language {
        case .english:
            english[key] ?? key
        case .vietnamese:
            vietnamese[key] ?? english[key] ?? key
        }
    }

    private static let english = [
        "all": "All",
        "text": "Text",
        "link": "Link",
        "code": "Code",
        "stack": "Stack",
        "clipboard": "Clipboard",
        "searchClipboard": "Search clipboard...",
        "emptyClipboard": "Copy something to start building local history.",
        "copy": "Copy",
        "copyNext": "Copy next",
        "clearStack": "Clear stack",
        "addToStack": "Add to stack",
        "addToBoard": "Add to board",
        "newBoard": "New board",
        "boardDefaultName": "Board",
        "rename": "Rename",
        "delete": "Delete",
        "renameBoard": "Rename board",
        "deleteBoard": "Delete board",
        "deleteBoardQuestion": "Delete board?",
        "deleteBoardMessage": "Clipboard items stay in All. Only this board is removed.",
        "boardName": "Board name",
        "save": "Save",
        "cancel": "Cancel",
        "settingsGeneral": "General",
        "settingsClipboard": "Clipboard",
        "settingsSync": "Sync",
        "settingsPrivacy": "Privacy",
        "launchAtLogin": "Launch at login",
        "appearance": "Appearance",
        "system": "System",
        "light": "Light",
        "dark": "Dark",
        "language": "Language",
        "pauseClipboard": "Pause clipboard monitoring",
        "clearClipboard": "Clear clipboard history",
        "cloudSync": "Cloud sync",
        "privacyBody": "Clipboard contents stay on this Mac unless you explicitly enable sync.",
        "openSettings": "Open Settings"
    ]

    private static let vietnamese = [
        "all": "Tất cả",
        "text": "Văn bản",
        "link": "Liên kết",
        "code": "Mã",
        "stack": "Stack",
        "clipboard": "Clipboard",
        "searchClipboard": "Tìm clipboard...",
        "emptyClipboard": "Hãy sao chép nội dung để bắt đầu lịch sử cục bộ.",
        "copy": "Sao chép",
        "copyNext": "Sao chép mục kế tiếp",
        "clearStack": "Xóa stack",
        "addToStack": "Thêm vào stack",
        "addToBoard": "Thêm vào board",
        "newBoard": "Board mới",
        "boardDefaultName": "Board",
        "rename": "Đổi tên",
        "delete": "Xóa",
        "renameBoard": "Đổi tên board",
        "deleteBoard": "Xóa board",
        "deleteBoardQuestion": "Xóa board?",
        "deleteBoardMessage": "Các mục clipboard vẫn nằm trong Tất cả. Chỉ board này bị xóa.",
        "boardName": "Tên board",
        "save": "Lưu",
        "cancel": "Hủy",
        "settingsGeneral": "Chung",
        "settingsClipboard": "Clipboard",
        "settingsSync": "Đồng bộ",
        "settingsPrivacy": "Riêng tư",
        "launchAtLogin": "Mở khi đăng nhập",
        "appearance": "Giao diện",
        "system": "Hệ thống",
        "light": "Sáng",
        "dark": "Tối",
        "language": "Ngôn ngữ",
        "pauseClipboard": "Tạm dừng theo dõi clipboard",
        "clearClipboard": "Xóa lịch sử clipboard",
        "cloudSync": "Đồng bộ đám mây",
        "privacyBody": "Nội dung clipboard ở lại trên máy Mac này trừ khi bạn bật đồng bộ.",
        "openSettings": "Mở cài đặt"
    ]
}
