import Combine
import SwiftUI

@MainActor
final class DayPlanViewModel: ObservableObject {
    @Published var showEveningReview = false
    @Published var showAddTaskForBlock: DayBlock?
}

struct DayPlanView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = DayPlanViewModel()
    @State private var energySelection: EnergyLevel = .medium

    private var todayProgress: Double {
        let all = store.tasks.filter { $0.dayBlock != nil }
        guard !all.isEmpty else { return 0 }
        return Double(all.filter(\.completed).count) / Double(all.count)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(spacing: 18) {
                        headerCard
                        energyCard
                        if !store.weekPriorities.isEmpty { prioritiesCard }

                        ForEach(DayBlock.allCases) { block in
                            blockCard(block)
                        }

                        if !store.unassignedTasks().isEmpty {
                            inboxCard
                        }

                        if store.shouldShowEveningReview {
                            ActionBannerCell(
                                icon: "moon.stars.fill",
                                title: "Evening Review",
                                subtitle: "Reflect on your day and plan tomorrow",
                                action: {
                                    FeedbackManager.lightTap()
                                    viewModel.showEveningReview = true
                                }
                            )
                        }

                        Spacer(minLength: 20)
                    }
                    .padding(AppLayout.padding)
                }
                .appScrollChrome()
            }
            .navigationTitle("Today")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        FeedbackManager.lightTap()
                        viewModel.showEveningReview = true
                    } label: {
                        Image(systemName: "moon.stars.fill")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color("AppPrimary"))
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(Color("AppSurface")))
                    }
                }
            }
            .sheet(isPresented: $viewModel.showEveningReview) {
                EveningReviewView().environmentObject(store)
            }
            .sheet(item: $viewModel.showAddTaskForBlock) { block in
                TaskFormView(task: nil, defaultDayBlock: block).environmentObject(store)
            }
            .onAppear { energySelection = store.currentEnergyLevel }
        }
        .appScreenChrome()
    }

    private var headerCard: some View {
        AppCard {
            HStack(spacing: 16) {
                AppProgressRing(progress: todayProgress, size: 64, lineWidth: 6)
                VStack(alignment: .leading, spacing: 6) {
                    Text(greeting)
                        .font(.title3.bold())
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text("Your day is \(Int(todayProgress * 100))% planned")
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                    HStack(spacing: 12) {
                        miniStat("\(store.tasks.filter { !$0.completed }.count)", label: "Open")
                        miniStat("\(store.focusSessionsToday)", label: "Focus")
                        miniStat(store.currentDayBlock().rawValue, label: "Now")
                    }
                }
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good Morning" }
        if hour < 17 { return "Good Afternoon" }
        return "Good Evening"
    }

    private func miniStat(_ value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color("AppPrimary"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 9, weight: .medium))
                .foregroundStyle(Color("AppTextSecondary"))
        }
    }

    private var energyCard: some View {
        AppCard(accent: Color("AppAccent")) {
            VStack(alignment: .leading, spacing: 12) {
                AppSectionHeader(title: "Energy Level", subtitle: "Tasks will match your focus", icon: "bolt.fill")
                EnergyLevelPicker(selection: $energySelection) { store.setEnergyLevel($0) }
                if let suggested = store.suggestedNextTask() {
                    HStack(spacing: 10) {
                        AppIconBadge(icon: "lightbulb.fill", size: 28, tint: Color("AppAccent"))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Up next")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(Color("AppTextSecondary"))
                            Text(suggested.title)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color("AppTextPrimary"))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color("AppBackground").opacity(0.4)))
                }
            }
        }
    }

    private var prioritiesCard: some View {
        AppCard(accent: Color("AppPrimary")) {
            VStack(alignment: .leading, spacing: 10) {
                AppSectionHeader(title: "Week Priorities", icon: "star.fill")
                ForEach(Array(store.weekPriorities.filter { !$0.isEmpty }.enumerated()), id: \.offset) { index, priority in
                    HStack(spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(Color("AppPrimary")))
                        Text(priority)
                            .font(.subheadline)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
            }
        }
    }

    private func blockCard(_ block: DayBlock) -> some View {
        let tasks = store.tasks(in: block)
        let habits = store.habits(for: block)
        return DayBlockCard(
            block: block,
            taskCount: tasks.count,
            habitCount: habits.count,
            onAdd: {
                FeedbackManager.lightTap()
                viewModel.showAddTaskForBlock = block
            },
            onFocus: {
                store.startFocusFromBlock(block, context: block.defaultContext, task: tasks.first)
            }
        ) {
            VStack(spacing: 8) {
                ForEach(habits) { habit in
                    HabitCell(habit: habit, onToggle: { store.toggleHabitToday(habit) })
                }
                if tasks.isEmpty && habits.isEmpty {
                    Text("Drop tasks here or tap +")
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                } else {
                    ForEach(tasks) { task in
                        TaskCell(
                            task: task,
                            projectName: store.projectName(for: task.projectId),
                            compact: true,
                            onToggle: { store.toggleTaskCompletion(task) },
                            onMove: { store.assignTask(task.id, to: $0) }
                        )
                        .draggable(task.id.uuidString)
                    }
                }
            }
        }
        .dropDestination(for: String.self) { items, _ in
            guard let id = items.first.flatMap({ UUID(uuidString: $0) }) else { return false }
            store.assignTask(id, to: block)
            return true
        }
    }

    private var inboxCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                AppSectionHeader(title: "Inbox", subtitle: "Drag into a time block", icon: "tray.fill")
                ForEach(store.unassignedTasks()) { task in
                    TaskCell(
                        task: task,
                        projectName: store.projectName(for: task.projectId),
                        compact: true,
                        onToggle: { store.toggleTaskCompletion(task) },
                        onMove: { store.assignTask(task.id, to: $0) }
                    )
                    .draggable(task.id.uuidString)
                }
            }
        }
    }
}
