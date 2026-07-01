import Combine
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var showDayPlan = false
    @Published var showEveningReview = false
    @Published var showAddTask = false
    @Published var showAddHabit = false
    @Published var energySelection: EnergyLevel = .medium
}

struct HomeView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = HomeViewModel()
    @Binding var selectedTab: AppTab

    init(selectedTab: Binding<AppTab> = .constant(.today)) {
        _selectedTab = selectedTab
    }

    private var todayProgress: Double {
        let planned = store.tasks.filter { $0.dayBlock != nil }
        guard !planned.isEmpty else {
            let all = store.tasks
            guard !all.isEmpty else { return 0 }
            return Double(all.filter(\.completed).count) / Double(all.count)
        }
        return Double(planned.filter(\.completed).count) / Double(planned.count)
    }

    private var pendingTasks: [TaskItem] {
        store.tasks.filter { !$0.completed }.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Good Morning" }
        if hour < 17 { return "Good Afternoon" }
        return "Good Evening"
    }

    private var dateText: String {
        Date().formatted(.dateTime.weekday(.wide).month(.wide).day())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(spacing: 18) {
                        heroBanner
                        quickActionsRow
                        HomeProgressWidget(
                            progress: todayProgress,
                            openTasks: store.tasks.filter { !$0.completed }.count,
                            completedToday: store.tasks.filter(\.completed).count,
                            focusSessions: store.focusSessionsToday,
                            streak: store.streakDays
                        )

                        widgetGrid

                        if store.shouldShowEveningReview {
                            ActionBannerCell(
                                icon: "moon.stars.fill",
                                title: "Evening Review",
                                subtitle: "Wrap up your day and plan tomorrow",
                                accent: Color("AppAccent")
                            ) {
                                viewModel.showEveningReview = true
                            }
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(AppLayout.padding)
                }
                .appScrollChrome()
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        FeedbackManager.lightTap()
                        viewModel.showDayPlan = true
                    } label: {
                        Image(systemName: "calendar")
                            .foregroundStyle(Color("AppPrimary"))
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(AppVisual.cellGradient)
                                    .overlay(Circle().strokeBorder(Color("AppPrimary").opacity(0.2), lineWidth: 1))
                            )
                    }
                }
            }
            .sheet(isPresented: $viewModel.showDayPlan) {
                NavigationStack {
                    DayPlanView()
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Done") {
                                    FeedbackManager.lightTap()
                                    viewModel.showDayPlan = false
                                }
                                .foregroundStyle(Color("AppPrimary"))
                            }
                        }
                }
                .environmentObject(store)
            }
            .sheet(isPresented: $viewModel.showEveningReview) {
                EveningReviewView().environmentObject(store)
            }
            .sheet(isPresented: $viewModel.showAddTask) {
                TaskFormView(task: nil).environmentObject(store)
            }
            .sheet(isPresented: $viewModel.showAddHabit) {
                HabitFormView(habit: nil).environmentObject(store)
            }
            .onAppear {
                viewModel.energySelection = store.currentEnergyLevel
            }
        }
        .appScreenChrome()
    }

    private var heroBanner: some View {
        ZStack(alignment: .bottomLeading) {
            Image("home_hero")
                .resizable()
                .scaledToFill()
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .clipped()

            LinearGradient(
                colors: [.clear, Color("AppBackground").opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(greeting)
                    .font(.title.bold())
                    .foregroundStyle(Color("AppTextPrimary"))
                Text(dateText)
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                if let next = store.suggestedNextTask() {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundStyle(Color("AppAccent"))
                        Text("Next: \(next.title)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(AppLayout.padding)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color("AppPrimary").opacity(0.4), Color("AppAccent").opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .compositingGroup()
        .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
    }

    private var quickActionsRow: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
            ForEach(HomeQuickAction.allCases) { action in
                HomeQuickActionButton(action: action) {
                    handleQuickAction(action)
                }
            }
        }
    }

    private var widgetGrid: some View {
        VStack(spacing: 14) {
            HomeFocusWidget(onStart: {
                if store.timerIsRunning {
                    store.stopFocusTimer()
                } else {
                    store.startFocusWithContext(store.activeFocusContext, task: store.suggestedNextTask())
                    selectedTab = .wellness
                }
            })

            HStack(alignment: .top, spacing: 14) {
                HomeTasksWidget(
                    tasks: pendingTasks,
                    onTaskTap: { task in
                        store.toggleTaskCompletion(task)
                    },
                    onSeeAll: { selectedTab = .tasks }
                )
            }

            HomeHabitsWidget(habits: store.habits) { habit in
                store.toggleHabitToday(habit)
            }

            HomeEnergyWidget(selection: $viewModel.energySelection) { level in
                store.setEnergyLevel(level)
            }

            if !store.weekPriorities.isEmpty {
                HomePrioritiesWidget(priorities: store.weekPriorities.filter { !$0.isEmpty })
            }

            ActionBannerCell(
                icon: "calendar.badge.clock",
                title: "Time Blocking",
                subtitle: "Open your full day plan with morning, afternoon and evening blocks",
                accent: Color("AppPrimary")
            ) {
                viewModel.showDayPlan = true
            }
        }
    }

    private func handleQuickAction(_ action: HomeQuickAction) {
        switch action {
        case .addTask:
            viewModel.showAddTask = true
        case .startFocus:
            store.startFocusWithContext(store.activeFocusContext, task: store.suggestedNextTask())
            selectedTab = .wellness
        case .addHabit:
            viewModel.showAddHabit = true
        case .dayPlan:
            viewModel.showDayPlan = true
        case .eveningReview:
            viewModel.showEveningReview = true
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
