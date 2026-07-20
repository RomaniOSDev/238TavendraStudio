import SwiftUI

struct DayScoreView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    private var report: DayScoreReport {
        store.todaysDayScore() ?? store.computeDayScore()
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    VStack(spacing: 18) {
                        hero
                        metrics
                        blockBreakdown
                        Text("Day Score blends block completion, energy match on finished tasks, and focus minutes — a planning grade, not a generic stats list.")
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .padding(.horizontal, 4)
                    }
                    .padding(AppLayout.padding)
                }
                .appScrollChrome()
            }
            .navigationTitle("Day Score")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        FeedbackManager.lightTap()
                        dismiss()
                    }
                    .foregroundStyle(Color("AppPrimary"))
                }
            }
            .onAppear {
                store.saveDayScoreIfNeeded()
            }
        }
        .appScreenChrome()
    }

    private var hero: some View {
        AppCard(accent: Color("AppPrimary")) {
            VStack(spacing: 12) {
                Text("\(report.overallScore)")
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("AppTextPrimary"))
                Text(report.gradeLabel)
                    .font(.title3.bold())
                    .foregroundStyle(Color("AppAccent"))
                Text("\(report.tasksCompleted) tasks · \(report.focusMinutes) focus min")
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
    }

    private var metrics: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                AppSectionHeader(title: "Score Breakdown", icon: "slider.horizontal.3")
                metricRow("Block completion", value: report.blockCompletion, weight: "45%")
                metricRow("Energy match", value: report.energyMatchRate, weight: "35%")
                metricRow("Focus intensity", value: min(Double(report.focusMinutes) / 60.0, 1.0), weight: "20%")
            }
        }
    }

    private func metricRow(_ title: String, value: Double, weight: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(Color("AppTextPrimary"))
                Spacer()
                Text(weight).font(.caption2.weight(.bold)).foregroundStyle(Color("AppAccent"))
                Text("\(Int(value * 100))%")
                    .font(.subheadline.bold())
                    .foregroundStyle(Color("AppTextPrimary"))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color("AppBackground").opacity(0.5))
                    Capsule()
                        .fill(AppVisual.buttonGradient)
                        .frame(width: max(8, geo.size.width * value))
                }
            }
            .frame(height: 8)
        }
    }

    private var blockBreakdown: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                AppSectionHeader(title: "By Time Block", icon: "calendar")
                blockRow(.morning, report.morningCompletion)
                blockRow(.afternoon, report.afternoonCompletion)
                blockRow(.evening, report.eveningCompletion)
            }
        }
    }

    private func blockRow(_ block: DayBlock, _ value: Double) -> some View {
        HStack {
            Image(systemName: block.iconName).foregroundStyle(Color("AppPrimary"))
            Text(block.rawValue).foregroundStyle(Color("AppTextPrimary"))
            Spacer()
            Text("\(Int(value * 100))%")
                .font(.headline.bold())
                .foregroundStyle(Color("AppAccent"))
        }
        .padding(.vertical, 4)
    }
}
