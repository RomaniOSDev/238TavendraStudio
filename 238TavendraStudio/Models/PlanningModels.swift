import Foundation

enum DayBlock: String, Codable, CaseIterable, Identifiable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .morning: return "sunrise.fill"
        case .afternoon: return "sun.max.fill"
        case .evening: return "moon.stars.fill"
        }
    }

    var timeRange: String {
        switch self {
        case .morning: return "6:00 – 12:00"
        case .afternoon: return "12:00 – 17:00"
        case .evening: return "17:00 – 22:00"
        }
    }

    var defaultContext: WorkContext {
        switch self {
        case .morning: return .deepWork
        case .afternoon: return .admin
        case .evening: return .creative
        }
    }
}

enum WorkContext: String, Codable, CaseIterable, Identifiable {
    case deepWork = "Deep Work"
    case admin = "Admin"
    case creative = "Creative"
    case breakTime = "Break"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .deepWork: return "brain.head.profile"
        case .admin: return "doc.text.fill"
        case .creative: return "paintbrush.fill"
        case .breakTime: return "cup.and.saucer.fill"
        }
    }

    var defaultDurationSec: Int {
        switch self {
        case .deepWork: return 3000
        case .admin: return 1500
        case .creative: return 2400
        case .breakTime: return 300
        }
    }

    var suggestedEnergy: EnergyLevel {
        switch self {
        case .deepWork: return .high
        case .admin: return .medium
        case .creative: return .high
        case .breakTime: return .low
        }
    }
}

enum EnergyLevel: String, Codable, CaseIterable, Identifiable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .high: return "bolt.fill"
        case .medium: return "gauge.medium"
        case .low: return "leaf.fill"
        }
    }
}

struct Project: Identifiable, Codable, Equatable {
    var id: UUID
    var name: String
    var deadline: Date?
    var sortOrder: Int

    init(id: UUID = UUID(), name: String, deadline: Date? = nil, sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.deadline = deadline
        self.sortOrder = sortOrder
    }
}

struct EnergyLog: Identifiable, Codable, Equatable {
    var id: UUID
    var level: EnergyLevel
    var date: Date

    init(id: UUID = UUID(), level: EnergyLevel, date: Date = Date()) {
        self.id = id
        self.level = level
        self.date = date
    }
}

struct WeeklyReviewRecord: Identifiable, Codable, Equatable {
    var id: UUID
    var weekStartDate: Date
    var completedAt: Date
    var stuckTaskIds: [UUID]
    var habitNotes: String
    var priorities: [String]

    init(
        id: UUID = UUID(),
        weekStartDate: Date,
        completedAt: Date = Date(),
        stuckTaskIds: [UUID] = [],
        habitNotes: String = "",
        priorities: [String] = []
    ) {
        self.id = id
        self.weekStartDate = weekStartDate
        self.completedAt = completedAt
        self.stuckTaskIds = stuckTaskIds
        self.habitNotes = habitNotes
        self.priorities = priorities
    }
}

struct EveningReviewState: Codable, Equatable {
    var lastReviewDate: Date?
    var carriedTaskIds: [UUID]

    init(lastReviewDate: Date? = nil, carriedTaskIds: [UUID] = []) {
        self.lastReviewDate = lastReviewDate
        self.carriedTaskIds = carriedTaskIds
    }
}

enum WeeklyReviewStep: Int, CaseIterable, Identifiable {
    case welcome = 0
    case completed
    case stuck
    case habits
    case priority1
    case priority2
    case priority3

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .welcome: return "Week in Review"
        case .completed: return "What You Completed"
        case .stuck: return "What Got Stuck"
        case .habits: return "Habits Check"
        case .priority1: return "Priority #1"
        case .priority2: return "Priority #2"
        case .priority3: return "Priority #3"
        }
    }
}
