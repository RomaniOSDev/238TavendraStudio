import Combine
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var showDayPlan = false
    @Published var showEveningReview = false
    @Published var showAddTask = false
    @Published var showAddHabit = false
    @Published var showDayScore = false
    @Published var energySelection: EnergyLevel = .medium
}

struct HomeView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = HomeViewModel()
    @Binding var selectedTab: AppTab

    init(selectedTab: Binding<AppTab> = .constant(.today)) {
        _selectedTab = selectedTab
    }

    private var recommendation: NowRecommendation {
        store.nowRecommendation()
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
                        EnergyForecastCard()
                        NowRecommendationCard(
                            recommendation: recommendation,
                            onStartFocus: {
                                let rec = recommendation
                                let context = rec.task?.workContext ?? rec.preferredContext
                                store.startFocusWithContext(context, task: rec.task)
                                selectedTab = .wellness
                            }
                        )

                        if !store.tomorrowMustTasks().isEmpty || !store.eveningReviewState.tomorrowMustIds.isEmpty {
                            TomorrowMustBoardCard(
                                tasks: store.tomorrowMustTasks(),
                                onToggle: { store.toggleTaskCompletion($0) },
                                onRemove: { store.removeFromTomorrowMust($0) }
                            )
                        }

                        DayScoreCard(
                            report: store.todaysDayScore() ?? store.computeDayScore(),
                            onOpen: { viewModel.showDayScore = true }
                        )

                        quickActionsRow

                        HomeFocusWidget(onStart: {
                            if store.timerIsRunning {
                                store.stopFocusTimer()
                            } else {
                                let rec = store.nowRecommendation()
                                store.startFocusWithContext(rec.task?.workContext ?? rec.preferredContext, task: rec.task)
                                selectedTab = .wellness
                            }
                        })

                        HomeHabitsWidget(habits: store.habits) { habit in
                            store.toggleHabitToday(habit)
                        }

                        if !store.weekPriorities.isEmpty {
                            HomePrioritiesWidget(priorities: store.weekPriorities.filter { !$0.isEmpty })
                        }

                        if store.shouldShowEveningReview {
                            ActionBannerCell(
                                icon: "moon.stars.fill",
                                title: "Evening Review + Day Score",
                                subtitle: "Carry unfinished work into Tomorrow Must and lock today's score",
                                accent: Color("AppAccent")
                            ) {
                                viewModel.showEveningReview = true
                            }
                        }

                        ActionBannerCell(
                            icon: "calendar.badge.clock",
                            title: "Time Blocking",
                            subtitle: "Plan Morning / Afternoon / Evening around your energy forecast",
                            accent: Color("AppPrimary")
                        ) {
                            viewModel.showDayPlan = true
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(AppLayout.padding)
                }
                .appScrollChrome()
            }
            .navigationTitle("Day OS")
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
            .sheet(isPresented: $viewModel.showDayScore) {
                DayScoreView().environmentObject(store)
            }
            .sheet(isPresented: $viewModel.showAddTask) {
                TaskFormView(task: nil).environmentObject(store)
            }
            .sheet(isPresented: $viewModel.showAddHabit) {
                HabitFormView(habit: nil).environmentObject(store)
            }
            .onAppear {
                store.ensureTodayForecast()
                viewModel.energySelection = store.energyForecast.level(for: store.currentDayBlock())
            }
        }
        .appScreenChrome()
    }

    private var heroBanner: some View {
        ZStack(alignment: .bottomLeading) {
            Image("home_hero")
                .resizable()
                .scaledToFill()
                .frame(height: 160)
                .frame(maxWidth: .infinity)
                .clipped()

            LinearGradient(
                colors: [.clear, Color("AppBackground").opacity(0.9)],
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
                Text("Energy × Blocks × Context")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color("AppAccent"))
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

    private func handleQuickAction(_ action: HomeQuickAction) {
        switch action {
        case .addTask:
            viewModel.showAddTask = true
        case .startFocus:
            let rec = store.nowRecommendation()
            store.startFocusWithContext(rec.task?.workContext ?? rec.preferredContext, task: rec.task)
            selectedTab = .wellness
        case .addHabit:
            viewModel.showAddHabit = true
        case .dayPlan:
            viewModel.showDayPlan = true
        case .eveningReview:
            viewModel.showEveningReview = true
        }
    }
}
