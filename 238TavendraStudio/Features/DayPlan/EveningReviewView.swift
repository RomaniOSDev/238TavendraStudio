import SwiftUI

struct EveningReviewView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    private var completed: [TaskItem] { store.tasks.filter(\.completed) }
    private var incomplete: [TaskItem] { store.incompleteTasksToday() }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                ScrollView {
                    VStack(spacing: 18) {
                        summaryCard
                        if !completed.isEmpty { completedSection }
                        if !incomplete.isEmpty { incompleteSection }
                        habitsSection
                        AppPrimaryButton(title: "Finish Review", icon: "checkmark.circle.fill") {
                            store.completeEveningReview()
                            dismiss()
                        }
                    }
                    .padding(AppLayout.padding)
                }
                .appScrollChrome()
            }
            .navigationTitle("Evening Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { FeedbackManager.lightTap(); dismiss() }
                        .foregroundStyle(Color("AppPrimary"))
                }
            }
        }
        .appScreenChrome()
    }

    private var summaryCard: some View {
        AppCard(accent: Color("AppAccent")) {
            VStack(alignment: .leading, spacing: 14) {
                AppSectionHeader(title: "Day Summary", subtitle: "How did today go?", icon: "moon.stars.fill")
                HStack(spacing: 10) {
                    summaryPill("\(completed.count)", label: "Done", icon: "checkmark")
                    summaryPill("\(incomplete.count)", label: "Open", icon: "clock")
                    summaryPill("\(store.focusSessionsToday)", label: "Focus", icon: "timer")
                }
            }
        }
    }

    private func summaryPill(_ value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            AppIconBadge(icon: icon, size: 28, tint: Color("AppPrimary"))
            Text(value).font(.headline.bold()).foregroundStyle(Color("AppTextPrimary"))
            Text(label).font(.caption2).foregroundStyle(Color("AppTextSecondary"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color("AppBackground").opacity(0.4)))
    }

    private var completedSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                AppSectionHeader(title: "Completed Today", icon: "checkmark.circle.fill")
                ForEach(completed.prefix(12)) { task in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Color("AppAccent"))
                        Text(task.title).font(.subheadline).foregroundStyle(Color("AppTextPrimary")).lineLimit(1)
                        Spacer()
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }

    private var incompleteSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                AppSectionHeader(title: "Still Open", icon: "clock.fill")
                ForEach(incomplete) { task in
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(task.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color("AppTextPrimary"))
                                .lineLimit(2)
                            if let block = task.dayBlock {
                                AppChip(text: block.rawValue, icon: block.iconName, style: .neutral)
                            }
                        }
                        Spacer()
                        Button("Carry Over") { store.carryTaskToTomorrow(task.id) }
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color("AppPrimary"))
                            .clipShape(Capsule())
                            .frame(minHeight: 44)
                    }
                    .padding(.vertical, 6)
                }
            }
        }
    }

    private var habitsSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                AppSectionHeader(title: "Habits Today", icon: "flame.fill")
                if store.habits.isEmpty {
                    Text("No habits tracked yet.").font(.caption).foregroundStyle(Color("AppTextSecondary"))
                } else {
                    ForEach(store.habits) { habit in
                        HStack {
                            Text(habit.title).font(.subheadline).foregroundStyle(Color("AppTextPrimary"))
                            Spacer()
                            Image(systemName: habit.isCompletedToday() ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(habit.isCompletedToday() ? Color("AppAccent") : Color("AppTextSecondary"))
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
    }
}
