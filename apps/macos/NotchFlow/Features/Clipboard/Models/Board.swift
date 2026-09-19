import Foundation

struct Board: Identifiable, Equatable, Codable {
    let id: UUID
    var name: String
    var sortOrder: Int
    let createdAt: Date
    var updatedAt: Date
}

struct RetentionPolicy: Equatable {
    let maxAgeHours: Int?
    let maxItems: Int

    static let free = RetentionPolicy(maxAgeHours: 24, maxItems: 50)
    static let proDefault = RetentionPolicy(maxAgeHours: nil, maxItems: 500)
}
