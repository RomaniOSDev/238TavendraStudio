import SwiftUI

struct StatsView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    StatsViewContent().padding(AppLayout.padding)
                }
                .appScrollChrome()
            }
            .navigationTitle("Stats")
        }
        .appScreenChrome()
    }
}

struct StatsViewContent: View {
    @EnvironmentObject private var store: AppDataStore

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 18) {
            summaryCard
            contextStatsCard
            EnergyStatsCard()
            achievementsGrid
        }
    }

    private var summaryCard: some View {
        AppCard(accent: Color("AppPrimary")) {
            VStack(alignment: .leading, spacing: 14) {
                AppSectionHeader(title: "Summary", subtitle: "Your productivity at a glance", icon: "chart.bar.fill")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    AppMetricTile(icon: "checkmark.circle.fill", value: "\(store.tasksCompleted)", label: "Tasks Done")
                    AppMetricTile(icon: "timer", value: "\(store.focusSessionsCompleted)", label: "Focus Sessions")
                    AppMetricTile(icon: "hourglass", value: "\(store.totalMinutesUsed)m", label: "Minutes Focused")
                    AppMetricTile(icon: "flame.fill", value: "\(store.streakDays)", label: "Day Streak")
                }
            }
        }
    }

    private var contextStatsCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                AppSectionHeader(title: "Focus by Context", icon: "brain.head.profile")
                ForEach(WorkContext.allCases) { context in
                    let count = store.focusSessions(for: context).count
                    HStack(spacing: 12) {
                        AppIconBadge(icon: context.iconName, size: 32, tint: Color("AppPrimary"))
                        Text(context.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color("AppTextPrimary"))
                        Spacer()
                        Text("\(count)")
                            .font(.headline.bold())
                            .foregroundStyle(Color("AppAccent"))
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var achievementsGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            AppSectionHeader(title: "Achievements", subtitle: "\(store.achievementsUnlocked.count) of 8 unlocked", icon: "star.fill")
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(AchievementCatalog.all) { achievement in
                    AchievementCell(
                        achievement: achievement,
                        isUnlocked: store.isAchievementUnlocked(achievement.id)
                    )
                }
            }
        }
    }
}
