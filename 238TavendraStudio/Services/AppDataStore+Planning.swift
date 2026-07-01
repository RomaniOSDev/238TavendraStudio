import Foundation

extension AppDataStore {

    // MARK: - Day Block

    func currentDayBlock(calendar: Calendar = .current) -> DayBlock {
        let hour = calendar.component(.hour, from: Date())
        if hour < 12 { return .morning }
        if hour < 17 { return .afternoon }
        return .evening
    }

    func tasks(in block: DayBlock, includeCompleted: Bool = false) -> [TaskItem] {
        tasks
            .filter { $0.dayBlock == block && (includeCompleted || !$0.completed) }
            .sorted { $0.blockSortOrder < $1.blockSortOrder }
    }

    func unassignedTasks() -> [TaskItem] {
        tasks.filter { $0.dayBlock == nil && !$0.completed }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    func habits(for block: DayBlock) -> [Habit] {
        habits.filter { $0.preferredDayBlock == block }
    }

    func assignTask(_ taskId: UUID, to block: DayBlock?) {
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        tasks[index].dayBlock = block
        if let block {
            let maxOrder = tasks.filter { $0.dayBlock == block }.map(\.blockSortOrder).max() ?? -1
            tasks[index].blockSortOrder = maxOrder + 1
        } else {
            tasks[index].blockSortOrder = 0
        }
        FeedbackManager.lightTap()
    }

    func moveTaskInBlock(_ taskId: UUID, toBlock block: DayBlock, atIndex destination: Int) {
        var blockTasks = tasks(in: block, includeCompleted: true)
        guard let fromIndex = blockTasks.firstIndex(where: { $0.id == taskId }) else { return }
        let item = blockTasks.remove(at: fromIndex)
        let insertIndex = min(max(destination, 0), blockTasks.count)
        blockTasks.insert(item, at: insertIndex)
        for (idx, task) in blockTasks.enumerated() {
            if let taskIndex = tasks.firstIndex(where: { $0.id == task.id }) {
                tasks[taskIndex].blockSortOrder = idx
            }
        }
    }

    func tasksCompletedToday() -> [TaskItem] {
        tasks.filter(\.completed)
    }

    func incompleteTasksToday() -> [TaskItem] {
        tasks.filter { !$0.completed }
    }

    // MARK: - Energy

    func setEnergyLevel(_ level: EnergyLevel) {
        currentEnergyLevel = level
        energyLogs.append(EnergyLog(level: level))
        recordMeaningfulActivity()
        FeedbackManager.lightTap()
    }

    func energyProductivityStats() -> [(level: EnergyLevel, count: Int)] {
        EnergyLevel.allCases.map { level in
            let count = energyLogs.filter { $0.level == level }.count
            return (level, count)
        }
    }

    func tasksMatchingCurrentEnergy() -> [TaskItem] {
        tasks.filter { !$0.completed && energyMatches(task: $0) }
    }

    func energyMatches(task: TaskItem) -> Bool {
        switch currentEnergyLevel {
        case .high:
            return task.energyLevel == .high || task.priority == .high || task.workContext == .deepWork
        case .medium:
            return task.energyLevel != .low
        case .low:
            return task.energyLevel == .low || task.workContext == .admin || task.priority == .low
        }
    }

    // MARK: - Contextual Focus

    func durationForContext(_ context: WorkContext) -> Int {
        contextDurations[context.rawValue] ?? context.defaultDurationSec
    }

    func setDurationForContext(_ context: WorkContext, seconds: Int) {
        contextDurations[context.rawValue] = seconds
        FeedbackManager.lightTap()
    }

    func suggestedNextTask() -> TaskItem? {
        let block = currentDayBlock()
        let pending = tasks.filter { !$0.completed }
        guard !pending.isEmpty else { return nil }

        let energyMatched = pending.filter { energyMatches(task: $0) }
        let pool = energyMatched.isEmpty ? pending : energyMatched

        if let inBlock = pool.first(where: { $0.dayBlock == block }) {
            return inBlock
        }
        if let contextMatch = pool.first(where: { $0.workContext == activeFocusContext }) {
            return contextMatch
        }
        if let priority = weekPriorities.first,
           let match = pool.first(where: { $0.title.localizedCaseInsensitiveContains(priority) || priority.localizedCaseInsensitiveContains($0.title) }) {
            return match
        }
        return pool.first
    }

    func startFocusFromBlock(_ block: DayBlock, context: WorkContext, task: TaskItem?) {
        activeDayBlock = block
        activeFocusContext = context
        activeLinkedTaskId = task?.id
        workDurationSec = durationForContext(context)
        currentTimerType = .work
        timerRemainingSec = workDurationSec
        startFocusTimer()
    }

    func startFocusWithContext(_ context: WorkContext, task: TaskItem?) {
        activeFocusContext = context
        activeLinkedTaskId = task?.id
        if let task, let block = task.dayBlock {
            activeDayBlock = block
        }
        workDurationSec = durationForContext(context)
        currentTimerType = .work
        if !timerIsRunning {
            timerRemainingSec = workDurationSec
        }
        startFocusTimer()
    }

    func linkedProjectIdForActiveTask() -> UUID? {
        guard let taskId = activeLinkedTaskId,
              let task = tasks.first(where: { $0.id == taskId }) else { return nil }
        return task.projectId
    }

    func focusSessions(for context: WorkContext) -> [FocusSessionRecord] {
        focusSessions.filter { $0.workContext == context && $0.type == .work }
    }

    func focusSessions(for projectId: UUID) -> [FocusSessionRecord] {
        focusSessions.filter { $0.projectId == projectId && $0.type == .work }
    }

    // MARK: - Projects

    func addProject(name: String, deadline: Date?) {
        let order = (projects.map(\.sortOrder).max() ?? -1) + 1
        projects.append(Project(name: name, deadline: deadline, sortOrder: order))
        recordMeaningfulActivity()
        FeedbackManager.success()
    }

    func updateProject(_ project: Project) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        projects[index] = project
    }

    func deleteProject(_ project: Project) {
        projects.removeAll { $0.id == project.id }
        for index in tasks.indices where tasks[index].projectId == project.id {
            tasks[index].projectId = nil
        }
        FeedbackManager.lightTap()
    }

    func tasks(for projectId: UUID) -> [TaskItem] {
        tasks.filter { $0.projectId == projectId }
    }

    func projectProgress(_ projectId: UUID) -> Double {
        let projectTasks = tasks(for: projectId)
        guard !projectTasks.isEmpty else { return 0 }
        let completed = projectTasks.filter(\.completed).count
        return Double(completed) / Double(projectTasks.count)
    }

    func projectName(for id: UUID?) -> String? {
        guard let id else { return nil }
        return projects.first(where: { $0.id == id })?.name
    }

    // MARK: - Evening Review

    var shouldShowEveningReview: Bool {
        let hour = Calendar.current.component(.hour, from: Date())
        guard hour >= 17 else { return false }
        if let last = eveningReviewState.lastReviewDate {
            return !Calendar.current.isDateInToday(last)
        }
        return !incompleteTasksToday().isEmpty || !tasks.filter(\.completed).isEmpty
    }

    func carryTaskToTomorrow(_ taskId: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        tasks[index].dayBlock = .morning
        tasks[index].blockSortOrder = (tasks.filter { $0.dayBlock == .morning }.map(\.blockSortOrder).max() ?? -1) + 1
        if !eveningReviewState.carriedTaskIds.contains(taskId) {
            eveningReviewState.carriedTaskIds.append(taskId)
        }
        FeedbackManager.lightTap()
    }

    func completeEveningReview() {
        eveningReviewState.lastReviewDate = Date()
        recordMeaningfulActivity()
        FeedbackManager.success()
    }

    // MARK: - Weekly Review

    func startOfWeek(for date: Date = Date(), calendar: Calendar = .current) -> Date {
        var cal = calendar
        cal.firstWeekday = 2
        let components = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return cal.date(from: components) ?? date
    }

    func hasCompletedWeeklyReviewThisWeek(calendar: Calendar = .current) -> Bool {
        let weekStart = startOfWeek(calendar: calendar)
        return weeklyReviews.contains { calendar.isDate($0.weekStartDate, inSameDayAs: weekStart) }
    }

    func tasksCompletedThisWeek(calendar: Calendar = .current) -> [TaskItem] {
        let weekStart = startOfWeek(calendar: calendar)
        return tasks.filter(\.completed)
    }

    func saveWeeklyReview(stuckTaskIds: [UUID], habitNotes: String, priorities: [String]) {
        let weekStart = startOfWeek()
        let record = WeeklyReviewRecord(
            weekStartDate: weekStart,
            stuckTaskIds: stuckTaskIds,
            habitNotes: habitNotes,
            priorities: priorities
        )
        weeklyReviews.insert(record, at: 0)
        weekPriorities = priorities
        for (index, priority) in priorities.enumerated() where !priority.isEmpty {
            let trimmed = priority.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            if !tasks.contains(where: { $0.title == trimmed && !$0.completed }) {
                addTask(
                    title: trimmed,
                    category: "Weekly Priority",
                    priority: index == 0 ? .high : .medium,
                    dayBlock: .morning,
                    workContext: .deepWork,
                    energyLevel: .high
                )
            }
        }
        recordMeaningfulActivity()
        FeedbackManager.success()
    }

    func habitsSummaryThisWeek() -> String {
        let active = habits.filter { $0.streak > 0 }
        if active.isEmpty { return "No active habits yet." }
        return active.map { "\($0.title): \($0.streak) day streak" }.joined(separator: "\n")
    }
}
