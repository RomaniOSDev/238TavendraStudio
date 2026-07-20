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
        ensureTodayForecast()
        var forecast = energyForecast
        forecast.set(level, for: currentDayBlock())
        energyForecast = forecast
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

    // MARK: - Contextual Focus

    func durationForContext(_ context: WorkContext) -> Int {
        contextDurations[context.rawValue] ?? context.defaultDurationSec
    }

    func setDurationForContext(_ context: WorkContext, seconds: Int) {
        contextDurations[context.rawValue] = seconds
        FeedbackManager.lightTap()
    }

    func suggestedNextTask() -> TaskItem? {
        nowRecommendation().task
    }

    /// Primary uniqueness loop: block + forecast energy + context rules → what to do now.
    func nowRecommendation() -> NowRecommendation {
        ensureTodayForecast()
        let block = currentDayBlock()
        let forecastEnergy = energyForecast.level(for: block)
        let preferred = ContextRuleEngine.preferredContext(for: forecastEnergy, block: block)
        let conflicts = ContextRuleEngine.conflicts(
            context: activeFocusContext,
            energy: forecastEnergy,
            block: block
        )

        let pending = tasks.filter { !$0.completed }
        let mustPool = tomorrowMustTasks().filter { !$0.completed }

        // Prefer Tomorrow Must that match current block/energy
        if let must = mustPool.first(where: { energyMatches(task: $0, energy: forecastEnergy) && ($0.dayBlock == block || $0.dayBlock == nil) }) {
            return NowRecommendation(
                block: block,
                forecastEnergy: forecastEnergy,
                preferredContext: preferred,
                task: must,
                reason: "Tomorrow Must · matches \(block.rawValue) + \(forecastEnergy.rawValue) energy",
                conflicts: conflicts
            )
        }

        let energyMatched = pending.filter { energyMatches(task: $0, energy: forecastEnergy) }
        let pool = energyMatched.isEmpty ? pending : energyMatched

        if let inBlock = pool.first(where: { $0.dayBlock == block && $0.workContext == preferred }) {
            return NowRecommendation(
                block: block,
                forecastEnergy: forecastEnergy,
                preferredContext: preferred,
                task: inBlock,
                reason: "Best fit for \(block.rawValue) · \(preferred.rawValue)",
                conflicts: conflicts
            )
        }
        if let inBlock = pool.first(where: { $0.dayBlock == block }) {
            return NowRecommendation(
                block: block,
                forecastEnergy: forecastEnergy,
                preferredContext: preferred,
                task: inBlock,
                reason: "Next in \(block.rawValue) block · \(forecastEnergy.rawValue) energy",
                conflicts: ContextRuleEngine.conflicts(context: inBlock.workContext, energy: forecastEnergy, block: block)
            )
        }
        if let contextMatch = pool.first(where: { $0.workContext == preferred }) {
            return NowRecommendation(
                block: block,
                forecastEnergy: forecastEnergy,
                preferredContext: preferred,
                task: contextMatch,
                reason: "Preferred context: \(preferred.rawValue)",
                conflicts: ContextRuleEngine.conflicts(context: contextMatch.workContext, energy: forecastEnergy, block: block)
            )
        }
        if let priority = weekPriorities.first,
           let match = pool.first(where: { $0.title.localizedCaseInsensitiveContains(priority) || priority.localizedCaseInsensitiveContains($0.title) }) {
            return NowRecommendation(
                block: block,
                forecastEnergy: forecastEnergy,
                preferredContext: preferred,
                task: match,
                reason: "Week priority match",
                conflicts: ContextRuleEngine.conflicts(context: match.workContext, energy: forecastEnergy, block: block)
            )
        }

        return NowRecommendation(
            block: block,
            forecastEnergy: forecastEnergy,
            preferredContext: preferred,
            task: pool.first,
            reason: pool.isEmpty
                ? "No open tasks — set forecast & add a block task"
                : "Closest available task for \(block.rawValue)",
            conflicts: conflicts
        )
    }

    func energyMatches(task: TaskItem, energy: EnergyLevel) -> Bool {
        switch energy {
        case .high:
            return task.energyLevel == .high || task.priority == .high || task.workContext == .deepWork
        case .medium:
            return task.energyLevel != .low
        case .low:
            return task.energyLevel == .low || task.workContext == .admin || task.priority == .low || task.workContext == .breakTime
        }
    }

    func contextConflicts(
        for context: WorkContext,
        energy: EnergyLevel? = nil,
        block: DayBlock? = nil
    ) -> [ContextConflict] {
        ensureTodayForecast()
        let b = block ?? currentDayBlock()
        let e = energy ?? energyForecast.level(for: b)
        return ContextRuleEngine.conflicts(context: context, energy: e, block: b)
    }

    // MARK: - Energy Forecast

    func ensureTodayForecast() {
        let today = Calendar.current.startOfDay(for: Date())
        if !Calendar.current.isDate(energyForecast.dayStart, inSameDayAs: today) {
            energyForecast = DayEnergyForecast(dayStart: today)
        }
    }

    func setForecastEnergy(_ level: EnergyLevel, for block: DayBlock) {
        ensureTodayForecast()
        var forecast = energyForecast
        forecast.set(level, for: block)
        energyForecast = forecast
        if block == currentDayBlock() {
            currentEnergyLevel = level
            energyLogs.append(EnergyLog(level: level))
        }
        recordMeaningfulActivity()
        FeedbackManager.lightTap()
    }

    // MARK: - Day Score

    func computeDayScore(calendar: Calendar = .current) -> DayScoreReport {
        ensureTodayForecast()
        func completion(for block: DayBlock) -> Double {
            let all = tasks.filter { $0.dayBlock == block }
            guard !all.isEmpty else { return 0 }
            return Double(all.filter(\.completed).count) / Double(all.count)
        }
        let morning = completion(for: .morning)
        let afternoon = completion(for: .afternoon)
        let evening = completion(for: .evening)
        let blocksWithTasks = DayBlock.allCases.filter { block in
            tasks.contains { $0.dayBlock == block }
        }
        let blockCompletion: Double
        if blocksWithTasks.isEmpty {
            let all = tasks
            blockCompletion = all.isEmpty ? 0 : Double(all.filter(\.completed).count) / Double(all.count)
        } else {
            let sum = blocksWithTasks.map { completion(for: $0) }.reduce(0, +)
            blockCompletion = sum / Double(blocksWithTasks.count)
        }

        let completedToday = tasks.filter(\.completed)
        let matchCount = completedToday.filter { task in
            guard let block = task.dayBlock else { return energyMatches(task: task, energy: currentEnergyLevel) }
            return energyMatches(task: task, energy: energyForecast.level(for: block))
        }.count
        let energyMatchRate = completedToday.isEmpty
            ? 0
            : Double(matchCount) / Double(completedToday.count)

        let focusMinutes = focusSessions
            .filter { calendar.isDateInToday($0.endDate) && $0.type == .work }
            .reduce(0) { $0 + Int($1.endDate.timeIntervalSince($1.startDate) / 60) }

        let score = Int(min(100, max(0,
            blockCompletion * 45 +
            energyMatchRate * 35 +
            min(Double(focusMinutes) / 60.0, 1.0) * 20
        ).rounded()))

        return DayScoreReport(
            date: Date(),
            blockCompletion: blockCompletion,
            energyMatchRate: energyMatchRate,
            focusMinutes: focusMinutes,
            tasksCompleted: completedToday.count,
            overallScore: score,
            morningCompletion: morning,
            afternoonCompletion: afternoon,
            eveningCompletion: evening
        )
    }

    func todaysDayScore() -> DayScoreReport? {
        dayScoreReports.first { Calendar.current.isDateInToday($0.date) }
    }

    @discardableResult
    func saveDayScoreIfNeeded() -> DayScoreReport {
        let report = computeDayScore()
        if let index = dayScoreReports.firstIndex(where: { Calendar.current.isDateInToday($0.date) }) {
            dayScoreReports[index] = report
        } else {
            dayScoreReports.insert(report, at: 0)
        }
        return report
    }

    // MARK: - Tomorrow Must (Carry-over board)

    func tomorrowMustTasks() -> [TaskItem] {
        let ids = eveningReviewState.tomorrowMustIds
        return ids.compactMap { id in tasks.first { $0.id == id && !$0.completed } }
    }

    func addToTomorrowMust(_ taskId: UUID) {
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else { return }
        tasks[index].dayBlock = .morning
        tasks[index].blockSortOrder = (tasks.filter { $0.dayBlock == .morning }.map(\.blockSortOrder).max() ?? -1) + 1
        var state = eveningReviewState
        if !state.carriedTaskIds.contains(taskId) {
            state.carriedTaskIds.append(taskId)
        }
        if !state.tomorrowMustIds.contains(taskId) {
            state.tomorrowMustIds.append(taskId)
        }
        eveningReviewState = state
        FeedbackManager.lightTap()
    }

    func removeFromTomorrowMust(_ taskId: UUID) {
        var state = eveningReviewState
        state.tomorrowMustIds.removeAll { $0 == taskId }
        eveningReviewState = state
        FeedbackManager.lightTap()
    }

    func clearCompletedFromTomorrowMust() {
        let completedIds = Set(tasks.filter(\.completed).map(\.id))
        var state = eveningReviewState
        state.tomorrowMustIds.removeAll { completedIds.contains($0) }
        eveningReviewState = state
    }

    func energyMatches(task: TaskItem) -> Bool {
        ensureTodayForecast()
        let energy = energyForecast.level(for: currentDayBlock())
        return energyMatches(task: task, energy: energy)
    }

    func carryTaskToTomorrow(_ taskId: UUID) {
        addToTomorrowMust(taskId)
    }

    func completeEveningReview() {
        _ = saveDayScoreIfNeeded()
        var state = eveningReviewState
        state.lastReviewDate = Date()
        eveningReviewState = state
        clearCompletedFromTomorrowMust()
        recordMeaningfulActivity()
        FeedbackManager.success()
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
