import Foundation

// MARK: - Priority Enum

enum Priority: String, Codable, CaseIterable, Comparable {
    case low    = "Low"
    case medium = "Medium"
    case high   = "High"

    /// Lower value = higher urgency (used for sorting)
    var sortOrder: Int {
        switch self {
        case .high:   return 0
        case .medium: return 1
        case .low:    return 2
        }
    }

    static func < (lhs: Priority, rhs: Priority) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }
}

// MARK: - Task Model

struct Task: Identifiable, Codable, Equatable {
    var id: UUID        = UUID()
    var title: String
    var description: String?
    var dueDate: Date?
    var priority: Priority
    var isCompleted: Bool = false
    var createdAt: Date   = Date()

    // Convenience initialiser keeps callers concise
    init(
        id: UUID = UUID(),
        title: String,
        description: String? = nil,
        dueDate: Date? = nil,
        priority: Priority = .medium,
        isCompleted: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id          = id
        self.title       = title
        self.description = description
        self.dueDate     = dueDate
        self.priority    = priority
        self.isCompleted = isCompleted
        self.createdAt   = createdAt
    }
}
