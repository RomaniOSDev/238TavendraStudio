import Combine
import SwiftUI

enum AppTab: Int, CaseIterable, Identifiable {
    case today
    case tasks
    case wellness
    case review
    case settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .today: return "Day OS"
        case .tasks: return "Tasks"
        case .wellness: return "Focus"
        case .review: return "Review"
        case .settings: return "Settings"
        }
    }

    var iconName: String {
        switch self {
        case .today: return "house.fill"
        case .tasks: return "checklist"
        case .wellness: return "timer"
        case .review: return "doc.text.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: AppTab
    @State private var pressedTab: AppTab?

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .appGlassPanel()
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private func tabButton(for tab: AppTab) -> some View {
        let isSelected = selectedTab == tab
        return Button {
            FeedbackManager.lightTap()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color("AppPrimary").opacity(0.35), Color("AppPrimary").opacity(0.1)],
                                    center: .center,
                                    startRadius: 4,
                                    endRadius: 20
                                )
                            )
                            .frame(width: 36, height: 36)
                    }
                    Image(systemName: tab.iconName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected ? Color("AppPrimary") : Color("AppTextSecondary"))
                }
                Text(tab.title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(isSelected ? Color("AppTextPrimary") : Color("AppTextSecondary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        isSelected
                            ? LinearGradient(
                                colors: [Color("AppPrimary").opacity(0.22), Color("AppAccent").opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(colors: [.clear, .clear], startPoint: .top, endPoint: .bottom)
                    )
            )
            .scaleEffect(pressedTab == tab ? 0.92 : 1)
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressedTab = tab }
                .onEnded { _ in pressedTab = nil }
        )
    }
}

struct MainTabView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var selectedTab: AppTab = .today

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                Group {
                    switch selectedTab {
                    case .today:
                        HomeView(selectedTab: $selectedTab)
                    case .tasks:
                        TasksView()
                    case .wellness:
                        WellnessHubView()
                    case .review:
                        ReviewHubView()
                    case .settings:
                        SettingsView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                CustomTabBar(selectedTab: $selectedTab)
            }
        }
        .achievementBanners(store: store)
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            store.checkTimerCompletion()
        }
    }
}

struct ReviewHubView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var showWeeklyReview = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(spacing: 16) {
                        weeklyReviewCard
                        StatsViewContent()
                    }
                    .padding(16)
                }
                .appScrollChrome()
            }
            .navigationTitle("Review")
            .fullScreenCover(isPresented: $showWeeklyReview) {
                WeeklyReviewView()
                    .environmentObject(store)
            }
        }
        .appScreenChrome()
    }

    private var weeklyReviewCard: some View {
        ActionBannerCell(
            icon: "calendar.badge.clock",
            title: "Weekly Review",
            subtitle: store.hasCompletedWeeklyReviewThisWeek()
                ? "Completed this week — great job!"
                : "Reflect on your week and set 3 priorities",
            accent: Color("AppPrimary")
        ) {
            FeedbackManager.lightTap()
            showWeeklyReview = true
        }
    }
}
