import Combine
import Foundation
import SwiftUI

struct AchievementBannerItem: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
}

@MainActor
final class AppDataStore: ObservableObject {
    static let shared = AppDataStore()

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private enum Keys {
        static let hasSeenOnboarding = "hasSeenOnboarding"
        static let tasks = "tasks"
        static let filterOption = "filterOption"
        static let habits = "habits"
        static let focusSessions = "focusSessions"
        static let sessionCount = "sessionCount"
        static let currentTimerType = "currentTimerType"
        static let workDurationSec = "workDurationSec"
        static let breakDurationSec = "breakDurationSec"
        static let focusPreset = "focusPreset"
        static let totalSessionsCompleted = "totalSessionsCompleted"
        static let focusSessionsCompleted = "focusSessionsCompleted"
        static let totalMinutesUsed = "totalMinutesUsed"
        static let tasksCompleted = "tasksCompleted"
        static let habitCheckIns = "habitCheckIns"
        static let streakDays = "streakDays"
        static let longestStreak = "longestStreak"
        static let lastActivityDate = "lastActivityDate"
        static let achievementsUnlocked = "achievementsUnlocked"
        static let timerEndDate = "timerEndDate"
        static let timerIsRunning = "timerIsRunning"
        static let timerRemainingSec = "timerRemainingSec"
        static let projects = "projects"
        static let currentEnergyLevel = "currentEnergyLevel"
        static let energyLogs = "energyLogs"
        static let weeklyReviews = "weeklyReviews"
        static let eveningReviewState = "eveningReviewState"
        static let contextDurations = "contextDurations"
        static let activeFocusContext = "activeFocusContext"
        static let activeDayBlock = "activeDayBlock"
        static let activeLinkedTaskId = "activeLinkedTaskId"
        static let weekPriorities = "weekPriorities"
    }

    @Published var hasSeenOnboarding: Bool {
        didSet { defaults.set(hasSeenOnboarding, forKey: Keys.hasSeenOnboarding) }
    }

    @Published var tasks: [TaskItem] {
        didSet { save(tasks, forKey: Keys.tasks) }
    }

    @Published var filterOption: TaskFilterOption {
        didSet { defaults.set(filterOption.rawValue, forKey: Keys.filterOption) }
    }

    @Published var habits: [Habit] {
        didSet { save(habits, forKey: Keys.habits) }
    }

    @Published var focusSessions: [FocusSessionRecord] {
        didSet { save(focusSessions, forKey: Keys.focusSessions) }
    }

    @Published var sessionCount: Int {
        didSet { defaults.set(sessionCount, forKey: Keys.sessionCount) }
    }

    @Published var currentTimerType: FocusTimerType {
        didSet { defaults.set(currentTimerType.rawValue, forKey: Keys.currentTimerType) }
    }

    @Published var workDurationSec: Int {
        didSet { defaults.set(workDurationSec, forKey: Keys.workDurationSec) }
    }

    @Published var breakDurationSec: Int {
        didSet { defaults.set(breakDurationSec, forKey: Keys.breakDurationSec) }
    }

    @Published var focusPreset: FocusPreset {
        didSet { defaults.set(focusPreset.rawValue, forKey: Keys.focusPreset) }
    }

    @Published var totalSessionsCompleted: Int {
        didSet { defaults.set(totalSessionsCompleted, forKey: Keys.totalSessionsCompleted) }
    }

    @Published var focusSessionsCompleted: Int {
        didSet { defaults.set(focusSessionsCompleted, forKey: Keys.focusSessionsCompleted) }
    }

    @Published var totalMinutesUsed: Int {
        didSet { defaults.set(totalMinutesUsed, forKey: Keys.totalMinutesUsed) }
    }

    @Published var tasksCompleted: Int {
        didSet { defaults.set(tasksCompleted, forKey: Keys.tasksCompleted) }
    }

    @Published var habitCheckIns: Int {
        didSet { defaults.set(habitCheckIns, forKey: Keys.habitCheckIns) }
    }

    @Published var streakDays: Int {
        didSet { defaults.set(streakDays, forKey: Keys.streakDays) }
    }

    @Published var longestStreak: Int {
        didSet { defaults.set(longestStreak, forKey: Keys.longestStreak) }
    }

    @Published var lastActivityDate: Date? {
        didSet {
            if let date = lastActivityDate {
                defaults.set(date, forKey: Keys.lastActivityDate)
            } else {
                defaults.removeObject(forKey: Keys.lastActivityDate)
            }
        }
    }

    @Published var achievementsUnlocked: [String: Date] {
        didSet { save(achievementsUnlocked, forKey: Keys.achievementsUnlocked) }
    }

    @Published var timerEndDate: Date? {
        didSet {
            if let date = timerEndDate {
                defaults.set(date, forKey: Keys.timerEndDate)
            } else {
                defaults.removeObject(forKey: Keys.timerEndDate)
            }
        }
    }

    @Published var timerIsRunning: Bool {
        didSet { defaults.set(timerIsRunning, forKey: Keys.timerIsRunning) }
    }

    @Published var projects: [Project] = [] {
        didSet { save(projects, forKey: Keys.projects) }
    }

    @Published var currentEnergyLevel: EnergyLevel = .medium {
        didSet { defaults.set(currentEnergyLevel.rawValue, forKey: Keys.currentEnergyLevel) }
    }

    @Published var energyLogs: [EnergyLog] = [] {
        didSet { save(energyLogs, forKey: Keys.energyLogs) }
    }

    @Published var weeklyReviews: [WeeklyReviewRecord] = [] {
        didSet { save(weeklyReviews, forKey: Keys.weeklyReviews) }
    }

    @Published var eveningReviewState: EveningReviewState = EveningReviewState() {
        didSet { save(eveningReviewState, forKey: Keys.eveningReviewState) }
    }

    @Published var contextDurations: [String: Int] = AppDataStore.defaultContextDurations() {
        didSet { save(contextDurations, forKey: Keys.contextDurations) }
    }

    @Published var activeFocusContext: WorkContext = .deepWork {
        didSet { defaults.set(activeFocusContext.rawValue, forKey: Keys.activeFocusContext) }
    }

    @Published var activeDayBlock: DayBlock? = nil {
        didSet {
            if let block = activeDayBlock {
                defaults.set(block.rawValue, forKey: Keys.activeDayBlock)
            } else {
                defaults.removeObject(forKey: Keys.activeDayBlock)
            }
        }
    }

    @Published var activeLinkedTaskId: UUID? = nil {
        didSet {
            if let id = activeLinkedTaskId {
                defaults.set(id.uuidString, forKey: Keys.activeLinkedTaskId)
            } else {
                defaults.removeObject(forKey: Keys.activeLinkedTaskId)
            }
        }
    }

    @Published var weekPriorities: [String] = [] {
        didSet { save(weekPriorities, forKey: Keys.weekPriorities) }
    }

    @Published var timerRemainingSec: Int = 1500

    @Published var currentAchievementBanner: AchievementBannerItem?
    @Published var sessionCompletionNotice: String?

    private var bannerQueue: [AchievementBannerItem] = []
    private var bannerTask: Task<Void, Never>?

    private init() {
        hasSeenOnboarding = defaults.bool(forKey: Keys.hasSeenOnboarding)
        tasks = Self.load([TaskItem].self, from: defaults, key: Keys.tasks, decoder: decoder) ?? []
        let filterRaw = defaults.string(forKey: Keys.filterOption) ?? TaskFilterOption.all.rawValue
        filterOption = TaskFilterOption(rawValue: filterRaw) ?? .all
        habits = Self.load([Habit].self, from: defaults, key: Keys.habits, decoder: decoder) ?? []
        focusSessions = Self.load([FocusSessionRecord].self, from: defaults, key: Keys.focusSessions, decoder: decoder) ?? []
        sessionCount = defaults.integer(forKey: Keys.sessionCount)
        let timerRaw = defaults.string(forKey: Keys.currentTimerType) ?? FocusTimerType.work.rawValue
        currentTimerType = FocusTimerType(rawValue: timerRaw) ?? .work
        workDurationSec = defaults.object(forKey: Keys.workDurationSec) as? Int ?? 1500
        breakDurationSec = defaults.object(forKey: Keys.breakDurationSec) as? Int ?? 300
        let presetRaw = defaults.string(forKey: Keys.focusPreset) ?? FocusPreset.short.rawValue
        focusPreset = FocusPreset(rawValue: presetRaw) ?? .short
        totalSessionsCompleted = defaults.integer(forKey: Keys.totalSessionsCompleted)
        focusSessionsCompleted = defaults.integer(forKey: Keys.focusSessionsCompleted)
        totalMinutesUsed = defaults.integer(forKey: Keys.totalMinutesUsed)
        tasksCompleted = defaults.integer(forKey: Keys.tasksCompleted)
        habitCheckIns = defaults.integer(forKey: Keys.habitCheckIns)
        streakDays = defaults.integer(forKey: Keys.streakDays)
        longestStreak = defaults.integer(forKey: Keys.longestStreak)
        lastActivityDate = defaults.object(forKey: Keys.lastActivityDate) as? Date
        achievementsUnlocked = Self.load([String: Date].self, from: defaults, key: Keys.achievementsUnlocked, decoder: decoder) ?? [:]
        timerEndDate = defaults.object(forKey: Keys.timerEndDate) as? Date
        timerIsRunning = defaults.bool(forKey: Keys.timerIsRunning)
        let savedRemaining = defaults.object(forKey: Keys.timerRemainingSec) as? Int
        timerRemainingSec = savedRemaining ?? workDurationSec

        projects = Self.load([Project].self, from: defaults, key: Keys.projects, decoder: decoder) ?? []
        let energyRaw = defaults.string(forKey: Keys.currentEnergyLevel) ?? EnergyLevel.medium.rawValue
        currentEnergyLevel = EnergyLevel(rawValue: energyRaw) ?? .medium
        energyLogs = Self.load([EnergyLog].self, from: defaults, key: Keys.energyLogs, decoder: decoder) ?? []
        weeklyReviews = Self.load([WeeklyReviewRecord].self, from: defaults, key: Keys.weeklyReviews, decoder: decoder) ?? []
        eveningReviewState = Self.load(EveningReviewState.self, from: defaults, key: Keys.eveningReviewState, decoder: decoder) ?? EveningReviewState()
        contextDurations = Self.load([String: Int].self, from: defaults, key: Keys.contextDurations, decoder: decoder) ?? Self.defaultContextDurations()
        let contextRaw = defaults.string(forKey: Keys.activeFocusContext) ?? WorkContext.deepWork.rawValue
        activeFocusContext = WorkContext(rawValue: contextRaw) ?? .deepWork
        if let blockRaw = defaults.string(forKey: Keys.activeDayBlock) {
            activeDayBlock = DayBlock(rawValue: blockRaw)
        } else {
            activeDayBlock = nil
        }
        if let taskIdRaw = defaults.string(forKey: Keys.activeLinkedTaskId) {
            activeLinkedTaskId = UUID(uuidString: taskIdRaw)
        } else {
            activeLinkedTaskId = nil
        }
        weekPriorities = Self.load([String].self, from: defaults, key: Keys.weekPriorities, decoder: decoder) ?? []

        registerForDataReset()
    }

    static func defaultContextDurations() -> [String: Int] {
        var map: [String: Int] = [:]
        for context in WorkContext.allCases {
            map[context.rawValue] = context.defaultDurationSec
        }
        return map
    }

    private func registerForDataReset() {
        NotificationCenter.default.addObserver(
            forName: .dataReset,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.reloadFromDefaults()
            }
        }
    }

    var filteredTasks: [TaskItem] {
        switch filterOption {
        case .all:
            return tasks.sorted { $0.sortOrder < $1.sortOrder }
        case .completed:
            return tasks.filter(\.completed).sorted { $0.sortOrder < $1.sortOrder }
        case .pending:
            return tasks.filter { !$0.completed }.sorted { $0.sortOrder < $1.sortOrder }
        }
    }

    var focusSessionsToday: Int {
        focusSessions.filter { Calendar.current.isDateInToday($0.endDate) }.count
    }

    func isAchievementUnlocked(_ id: String) -> Bool {
        achievementsUnlocked[id] != nil
    }

    func recordMeaningfulActivity() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if let last = lastActivityDate {
            let lastDay = calendar.startOfDay(for: last)
            let diff = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if diff == 0 {
                // same day
            } else if diff == 1 {
                streakDays += 1
            } else {
                streakDays = 1
            }
        } else {
            streakDays = 1
        }

        longestStreak = max(longestStreak, streakDays)
        lastActivityDate = Date()
        evaluateAchievements()
    }

    func completeOnboarding() {
        hasSeenOnboarding = true
        FeedbackManager.lightTap()
    }

    func addTask(
        title: String,
        category: String,
        priority: TaskPriority,
        dayBlock: DayBlock? = nil,
        workContext: WorkContext = .deepWork,
        projectId: UUID? = nil,
        energyLevel: EnergyLevel? = nil
    ) {
        let order = (tasks.map(\.sortOrder).max() ?? -1) + 1
        let blockOrder: Int
        if let block = dayBlock {
            blockOrder = (tasks.filter { $0.dayBlock == block }.map(\.blockSortOrder).max() ?? -1) + 1
        } else {
            blockOrder = 0
        }
        let energy = energyLevel ?? workContext.suggestedEnergy
        let task = TaskItem(
            title: title,
            category: category,
            priority: priority,
            sortOrder: order,
            dayBlock: dayBlock,
            workContext: workContext,
            projectId: projectId,
            energyLevel: energy,
            blockSortOrder: blockOrder
        )
        tasks.append(task)
        recordMeaningfulActivity()
        FeedbackManager.success()
        evaluateAchievements()
    }

    func updateTask(_ task: TaskItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index] = task
    }

    func toggleTaskCompletion(_ task: TaskItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        let wasCompleted = tasks[index].completed
        tasks[index].completed.toggle()
        if !wasCompleted && tasks[index].completed {
            tasksCompleted += 1
            recordMeaningfulActivity()
            FeedbackManager.taskComplete()
            evaluateAchievements()
        } else {
            FeedbackManager.lightTap()
        }
    }

    func deleteTask(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
        FeedbackManager.lightTap()
    }

    func moveTasks(from source: IndexSet, to destination: Int, in list: [TaskItem]) {
        var reordered = list
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, item) in reordered.enumerated() {
            if let taskIndex = tasks.firstIndex(where: { $0.id == item.id }) {
                tasks[taskIndex].sortOrder = index
            }
        }
    }

    func addHabit(title: String, preferredDayBlock: DayBlock = .morning) {
        habits.append(Habit(title: title, preferredDayBlock: preferredDayBlock))
        recordMeaningfulActivity()
        FeedbackManager.success()
    }

    func updateHabit(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        habits[index] = habit
    }

    func deleteHabit(_ habit: Habit) {
        habits.removeAll { $0.id == habit.id }
        FeedbackManager.lightTap()
    }

    func toggleHabitToday(_ habit: Habit) {
        guard let index = habits.firstIndex(where: { $0.id == habit.id }) else { return }
        let calendar = Calendar.current
        if habits[index].isCompletedToday(calendar: calendar) {
            habits[index].completedDates.removeAll { calendar.isDateInToday($0) }
            recalculateHabitStreak(at: index, calendar: calendar)
            FeedbackManager.lightTap()
            return
        }

        habits[index].completedDates.append(Date())
        habitCheckIns += 1
        recalculateHabitStreak(at: index, calendar: calendar)
        recordMeaningfulActivity()
        FeedbackManager.focusComplete()
        evaluateAchievements()
    }

    private func recalculateHabitStreak(at index: Int, calendar: Calendar) {
        let sortedDays = Set(habits[index].completedDates.map { calendar.startOfDay(for: $0) }).sorted(by: >)
        var streak = 0
        var expected = calendar.startOfDay(for: Date())
        for day in sortedDays {
            if day == expected {
                streak += 1
                expected = calendar.date(byAdding: .day, value: -1, to: expected) ?? expected
            } else if day < expected {
                break
            }
        }
        habits[index].streak = streak
    }

    func deleteFocusSession(_ session: FocusSessionRecord) {
        focusSessions.removeAll { $0.id == session.id }
        FeedbackManager.lightTap()
    }

    func startFocusTimer() {
        let duration = currentTimerType == .work ? workDurationSec : breakDurationSec
        timerRemainingSec = duration
        timerEndDate = Date().addingTimeInterval(TimeInterval(duration))
        timerIsRunning = true
        persistTimerSnapshot()
        FeedbackManager.mediumAction()
    }

    func stopFocusTimer() {
        timerIsRunning = false
        timerEndDate = nil
        timerRemainingSec = currentTimerType == .work ? workDurationSec : breakDurationSec
        persistTimerSnapshot()
        FeedbackManager.lightTap()
    }

    func completeFocusSession() {
        guard timerIsRunning else { return }

        let completedType = currentTimerType
        let duration = completedType == .work ? workDurationSec : breakDurationSec
        timerIsRunning = false
        timerEndDate = nil

        let end = Date()
        let start = end.addingTimeInterval(-TimeInterval(duration))
        let record = FocusSessionRecord(
            startDate: start,
            endDate: end,
            type: completedType,
            workContext: completedType == .work ? activeFocusContext : nil,
            projectId: linkedProjectIdForActiveTask(),
            dayBlock: activeDayBlock,
            linkedTaskId: activeLinkedTaskId
        )
        focusSessions.insert(record, at: 0)
        sessionCount += 1
        totalSessionsCompleted += 1

        if completedType == .work {
            focusSessionsCompleted += 1
            totalMinutesUsed += duration / 60
            sessionCompletionNotice = "Time for a break!"
        } else {
            sessionCompletionNotice = "Back to work!"
        }

        recordMeaningfulActivity()
        FeedbackManager.focusComplete()
        evaluateAchievements()

        if completedType == .work {
            currentTimerType = .breakTime
            timerRemainingSec = breakDurationSec
        } else {
            currentTimerType = .work
            timerRemainingSec = workDurationSec
        }
        persistTimerSnapshot()
    }

    func displayRemainingSeconds(at now: Date = Date()) -> Int {
        if timerIsRunning, let end = timerEndDate {
            return max(0, Int(end.timeIntervalSince(now).rounded(.up)))
        }
        return timerRemainingSec
    }

    func timerProgress(at now: Date = Date()) -> Double {
        let total = Double(currentTimerType == .work ? durationForContext(activeFocusContext) : breakDurationSec)
        guard total > 0 else { return 0 }
        let remaining = Double(displayRemainingSeconds(at: now))
        return min(1, max(0, 1 - remaining / total))
    }

    func checkTimerCompletion(at now: Date = Date()) {
        guard timerIsRunning, let end = timerEndDate, now >= end else { return }
        completeFocusSession()
    }

    func syncTimerRemaining(now: Date = Date()) {
        checkTimerCompletion(at: now)
    }

    private func persistTimerSnapshot() {
        defaults.set(timerRemainingSec, forKey: Keys.timerRemainingSec)
    }

    func applyFocusPreset(_ preset: FocusPreset) {
        focusPreset = preset
        if !timerIsRunning {
            timerRemainingSec = currentTimerType == .work ? workDurationSec : breakDurationSec
        }
        FeedbackManager.lightTap()
    }

    func resetAllData() {
        let domain = Bundle.main.bundleIdentifier ?? ""
        defaults.removePersistentDomain(forName: domain)
        defaults.synchronize()
        reloadFromDefaults()
        bannerQueue.removeAll()
        currentAchievementBanner = nil
        bannerTask?.cancel()
    }

    private func reloadFromDefaults() {
        hasSeenOnboarding = defaults.bool(forKey: Keys.hasSeenOnboarding)
        tasks = Self.load([TaskItem].self, from: defaults, key: Keys.tasks, decoder: decoder) ?? []
        filterOption = .all
        habits = []
        focusSessions = []
        sessionCount = 0
        currentTimerType = .work
        workDurationSec = 1500
        breakDurationSec = 300
        focusPreset = .short
        totalSessionsCompleted = 0
        focusSessionsCompleted = 0
        totalMinutesUsed = 0
        tasksCompleted = 0
        habitCheckIns = 0
        streakDays = 0
        longestStreak = 0
        lastActivityDate = nil
        achievementsUnlocked = [:]
        timerEndDate = nil
        timerIsRunning = false
        timerRemainingSec = workDurationSec
        projects = []
        currentEnergyLevel = .medium
        energyLogs = []
        weeklyReviews = []
        eveningReviewState = EveningReviewState()
        contextDurations = Self.defaultContextDurations()
        activeFocusContext = .deepWork
        activeDayBlock = nil
        activeLinkedTaskId = nil
        weekPriorities = []
    }

    func evaluateAchievements() {
        var newlyUnlocked: [AchievementDefinition] = []

        for achievement in AchievementCatalog.all {
            guard achievementsUnlocked[achievement.id] == nil else { continue }
            if isConditionMet(for: achievement.id) {
                achievementsUnlocked[achievement.id] = Date()
                newlyUnlocked.append(achievement)
            }
        }

        for achievement in newlyUnlocked {
            enqueueBanner(AchievementBannerItem(
                id: achievement.id,
                title: achievement.title,
                description: achievement.description
            ))
            FeedbackManager.achievementUnlocked()
        }
    }

    private func isConditionMet(for id: String) -> Bool {
        switch id {
        case "first_task":
            return tasksCompleted >= 1
        case "focused_starter":
            return focusSessionsCompleted >= 5
        case "habit_initiator":
            return habitCheckIns >= 3
        case "task_tracker_pro":
            return tasksCompleted >= 20
        case "getting_going":
            return tasksCompleted >= 10
        case "power_user":
            return tasksCompleted >= 50
        case "three_day_streak":
            return longestStreak >= 3
        case "week_long_habit":
            return longestStreak >= 7
        default:
            return false
        }
    }

    private func enqueueBanner(_ item: AchievementBannerItem) {
        bannerQueue.append(item)
        guard bannerTask == nil else { return }
        showNextBanner()
    }

    private func showNextBanner() {
        guard !bannerQueue.isEmpty else {
            bannerTask = nil
            return
        }
        let next = bannerQueue.removeFirst()
        currentAchievementBanner = next
        bannerTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation(.easeInOut(duration: 0.3)) {
                currentAchievementBanner = nil
            }
            try? await Task.sleep(nanoseconds: 400_000_000)
            showNextBanner()
        }
    }

    private func save<T: Encodable>(_ value: T, forKey key: String) {
        if let data = try? encoder.encode(value) {
            defaults.set(data, forKey: key)
        }
    }

    private static func load<T: Decodable>(
        _ type: T.Type,
        from defaults: UserDefaults,
        key: String,
        decoder: JSONDecoder
    ) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? decoder.decode(type, from: data)
    }
}
