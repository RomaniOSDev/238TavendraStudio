import Foundation

extension Notification.Name {
    static let dataReset = Notification.Name("dataReset")
}

enum TaskPriority: String, Codable, CaseIterable, Identifiable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"

    var id: String { rawValue }
}

struct TaskItem: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var completed: Bool
    var category: String
    var priority: TaskPriority
    var sortOrder: Int
    var dayBlock: DayBlock?
    var workContext: WorkContext
    var projectId: UUID?
    var energyLevel: EnergyLevel
    var blockSortOrder: Int

    init(
        id: UUID = UUID(),
        title: String,
        completed: Bool = false,
        category: String = "General",
        priority: TaskPriority = .medium,
        sortOrder: Int = 0,
        dayBlock: DayBlock? = nil,
        workContext: WorkContext = .deepWork,
        projectId: UUID? = nil,
        energyLevel: EnergyLevel = .medium,
        blockSortOrder: Int = 0
    ) {
        self.id = id
        self.title = title
        self.completed = completed
        self.category = category
        self.priority = priority
        self.sortOrder = sortOrder
        self.dayBlock = dayBlock
        self.workContext = workContext
        self.projectId = projectId
        self.energyLevel = energyLevel
        self.blockSortOrder = blockSortOrder
    }

    enum CodingKeys: String, CodingKey {
        case id, title, completed, category, priority, sortOrder
        case dayBlock, workContext, projectId, energyLevel, blockSortOrder
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        completed = try container.decode(Bool.self, forKey: .completed)
        category = try container.decode(String.self, forKey: .category)
        priority = try container.decode(TaskPriority.self, forKey: .priority)
        sortOrder = try container.decode(Int.self, forKey: .sortOrder)
        dayBlock = try container.decodeIfPresent(DayBlock.self, forKey: .dayBlock)
        workContext = try container.decodeIfPresent(WorkContext.self, forKey: .workContext) ?? .deepWork
        projectId = try container.decodeIfPresent(UUID.self, forKey: .projectId)
        energyLevel = try container.decodeIfPresent(EnergyLevel.self, forKey: .energyLevel) ?? .medium
        blockSortOrder = try container.decodeIfPresent(Int.self, forKey: .blockSortOrder) ?? 0
    }
}

struct Habit: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var streak: Int
    var completedDates: [Date]
    var preferredDayBlock: DayBlock

    init(
        id: UUID = UUID(),
        title: String,
        streak: Int = 0,
        completedDates: [Date] = [],
        preferredDayBlock: DayBlock = .morning
    ) {
        self.id = id
        self.title = title
        self.streak = streak
        self.completedDates = completedDates
        self.preferredDayBlock = preferredDayBlock
    }

    enum CodingKeys: String, CodingKey {
        case id, title, streak, completedDates, preferredDayBlock
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        streak = try container.decode(Int.self, forKey: .streak)
        completedDates = try container.decode([Date].self, forKey: .completedDates)
        preferredDayBlock = try container.decodeIfPresent(DayBlock.self, forKey: .preferredDayBlock) ?? .morning
    }

    func isCompletedToday(calendar: Calendar = .current) -> Bool {
        completedDates.contains { calendar.isDateInToday($0) }
    }
}

enum FocusTimerType: String, Codable {
    case work = "Work"
    case breakTime = "Break"
}

struct FocusSessionRecord: Identifiable, Codable, Equatable {
    var id: UUID
    var startDate: Date
    var endDate: Date
    var type: FocusTimerType
    var workContext: WorkContext?
    var projectId: UUID?
    var dayBlock: DayBlock?
    var linkedTaskId: UUID?

    init(
        id: UUID = UUID(),
        startDate: Date,
        endDate: Date,
        type: FocusTimerType,
        workContext: WorkContext? = nil,
        projectId: UUID? = nil,
        dayBlock: DayBlock? = nil,
        linkedTaskId: UUID? = nil
    ) {
        self.id = id
        self.startDate = startDate
        self.endDate = endDate
        self.type = type
        self.workContext = workContext
        self.projectId = projectId
        self.dayBlock = dayBlock
        self.linkedTaskId = linkedTaskId
    }

    enum CodingKeys: String, CodingKey {
        case id, startDate, endDate, type, workContext, projectId, dayBlock, linkedTaskId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decode(Date.self, forKey: .endDate)
        type = try container.decode(FocusTimerType.self, forKey: .type)
        workContext = try container.decodeIfPresent(WorkContext.self, forKey: .workContext)
        projectId = try container.decodeIfPresent(UUID.self, forKey: .projectId)
        dayBlock = try container.decodeIfPresent(DayBlock.self, forKey: .dayBlock)
        linkedTaskId = try container.decodeIfPresent(UUID.self, forKey: .linkedTaskId)
    }
}

struct AchievementDefinition: Identifiable {
    let id: String
    let title: String
    let description: String
    let iconName: String
}

enum AchievementCatalog {
    static let all: [AchievementDefinition] = [
        AchievementDefinition(
            id: "first_task",
            title: "First Task",
            description: "You completed your first task.",
            iconName: "checkmark.circle.fill"
        ),
        AchievementDefinition(
            id: "focused_starter",
            title: "Focused Starter",
            description: "Complete 5 focus sessions.",
            iconName: "timer"
        ),
        AchievementDefinition(
            id: "habit_initiator",
            title: "Habit Initiator",
            description: "Check in on a habit three times.",
            iconName: "flame.fill"
        ),
        AchievementDefinition(
            id: "task_tracker_pro",
            title: "Task Tracker Pro",
            description: "Complete 20 tasks.",
            iconName: "list.bullet.clipboard.fill"
        ),
        AchievementDefinition(
            id: "getting_going",
            title: "Getting Going",
            description: "Reached 10 items.",
            iconName: "arrow.up.circle.fill"
        ),
        AchievementDefinition(
            id: "power_user",
            title: "Power User",
            description: "Reached 50 items.",
            iconName: "bolt.fill"
        ),
        AchievementDefinition(
            id: "three_day_streak",
            title: "Three-Day Streak",
            description: "Used the app 3 days in a row.",
            iconName: "calendar"
        ),
        AchievementDefinition(
            id: "week_long_habit",
            title: "Week-Long Habit",
            description: "Used the app 7 days in a row.",
            iconName: "star.fill"
        )
    ]
}

enum TaskFilterOption: String, CaseIterable, Identifiable {
    case all = "All"
    case completed = "Completed"
    case pending = "Pending"

    var id: String { rawValue }
}

enum FocusPreset: String, CaseIterable, Identifiable {
    case short = "25/5"
    case long = "50/10"

    var id: String { rawValue }

    var workDurationSec: Int {
        switch self {
        case .short: return 1500
        case .long: return 3000
        }
    }

    var breakDurationSec: Int {
        switch self {
        case .short: return 300
        case .long: return 600
        }
    }
}
