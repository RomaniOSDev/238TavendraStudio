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
    /// Explicit "Tomorrow Must" queue (subset of carried / unfinished).
    var tomorrowMustIds: [UUID]

    init(
        lastReviewDate: Date? = nil,
        carriedTaskIds: [UUID] = [],
        tomorrowMustIds: [UUID] = []
    ) {
        self.lastReviewDate = lastReviewDate
        self.carriedTaskIds = carriedTaskIds
        self.tomorrowMustIds = tomorrowMustIds
    }

    enum CodingKeys: String, CodingKey {
        case lastReviewDate, carriedTaskIds, tomorrowMustIds
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        lastReviewDate = try c.decodeIfPresent(Date.self, forKey: .lastReviewDate)
        carriedTaskIds = try c.decodeIfPresent([UUID].self, forKey: .carriedTaskIds) ?? []
        tomorrowMustIds = try c.decodeIfPresent([UUID].self, forKey: .tomorrowMustIds) ?? []
    }
}

// MARK: - Energy Forecast (per day-block)

struct DayEnergyForecast: Codable, Equatable {
    var dayStart: Date
    var morning: EnergyLevel
    var afternoon: EnergyLevel
    var evening: EnergyLevel

    init(
        dayStart: Date = Calendar.current.startOfDay(for: Date()),
        morning: EnergyLevel = .high,
        afternoon: EnergyLevel = .medium,
        evening: EnergyLevel = .low
    ) {
        self.dayStart = dayStart
        self.morning = morning
        self.afternoon = afternoon
        self.evening = evening
    }

    func level(for block: DayBlock) -> EnergyLevel {
        switch block {
        case .morning: return morning
        case .afternoon: return afternoon
        case .evening: return evening
        }
    }

    mutating func set(_ level: EnergyLevel, for block: DayBlock) {
        switch block {
        case .morning: morning = level
        case .afternoon: afternoon = level
        case .evening: evening = level
        }
    }

    var isDefault: Bool {
        morning == .high && afternoon == .medium && evening == .low
    }
}

// MARK: - Day Score

struct DayScoreReport: Identifiable, Codable, Equatable {
    var id: UUID
    var date: Date
    var blockCompletion: Double
    var energyMatchRate: Double
    var focusMinutes: Int
    var tasksCompleted: Int
    var overallScore: Int
    var morningCompletion: Double
    var afternoonCompletion: Double
    var eveningCompletion: Double

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        blockCompletion: Double = 0,
        energyMatchRate: Double = 0,
        focusMinutes: Int = 0,
        tasksCompleted: Int = 0,
        overallScore: Int = 0,
        morningCompletion: Double = 0,
        afternoonCompletion: Double = 0,
        eveningCompletion: Double = 0
    ) {
        self.id = id
        self.date = date
        self.blockCompletion = blockCompletion
        self.energyMatchRate = energyMatchRate
        self.focusMinutes = focusMinutes
        self.tasksCompleted = tasksCompleted
        self.overallScore = overallScore
        self.morningCompletion = morningCompletion
        self.afternoonCompletion = afternoonCompletion
        self.eveningCompletion = eveningCompletion
    }

    var gradeLabel: String {
        switch overallScore {
        case 90...100: return "Peak Day"
        case 75..<90: return "Strong Day"
        case 55..<75: return "Solid Day"
        case 35..<55: return "Mixed Day"
        default: return "Reset Day"
        }
    }
}

// MARK: - Context Rules

struct ContextConflict: Identifiable, Equatable {
    let id: String
    let title: String
    let message: String
}

enum ContextRuleEngine {
    /// Built-in rules that make the planning loop distinct.
    static func conflicts(
        context: WorkContext,
        energy: EnergyLevel,
        block: DayBlock
    ) -> [ContextConflict] {
        var list: [ContextConflict] = []

        if context == .deepWork && energy != .high {
            list.append(ContextConflict(
                id: "deepwork-energy",
                title: "Energy mismatch",
                message: "Deep Work works best at High energy. Consider Admin or wait for a High block."
            ))
        }
        if context == .deepWork && block == .evening {
            list.append(ContextConflict(
                id: "deepwork-evening",
                title: "Block mismatch",
                message: "Deep Work is intended for Morning. Evening suits Creative or Break."
            ))
        }
        if context == .creative && energy == .low {
            list.append(ContextConflict(
                id: "creative-low",
                title: "Low creative energy",
                message: "Creative sessions need Medium or High energy for better output."
            ))
        }
        if context == .admin && energy == .high && block == .morning {
            list.append(ContextConflict(
                id: "admin-peak",
                title: "Peak hours spent on Admin",
                message: "Morning + High energy is ideal for Deep Work — save Admin for Afternoon."
            ))
        }
        if context == .breakTime && energy == .high {
            list.append(ContextConflict(
                id: "break-high",
                title: "High energy on Break",
                message: "You have High energy — consider a short Deep Work burst before Break."
            ))
        }
        return list
    }

    static func preferredContext(for energy: EnergyLevel, block: DayBlock) -> WorkContext {
        switch (block, energy) {
        case (.morning, .high): return .deepWork
        case (.morning, .medium): return .creative
        case (.morning, .low): return .admin
        case (.afternoon, .high): return .creative
        case (.afternoon, .medium): return .admin
        case (.afternoon, .low): return .breakTime
        case (.evening, .high): return .creative
        case (.evening, .medium): return .admin
        case (.evening, .low): return .breakTime
        }
    }
}

// MARK: - Now Recommendation

struct NowRecommendation: Equatable {
    var block: DayBlock
    var forecastEnergy: EnergyLevel
    var preferredContext: WorkContext
    var task: TaskItem?
    var reason: String
    var conflicts: [ContextConflict]
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
