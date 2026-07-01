import Combine
import SwiftUI

@MainActor
final class WeeklyReviewViewModel: ObservableObject {
    @Published var currentStep: WeeklyReviewStep = .welcome
    @Published var selectedStuckIds: Set<UUID> = []
    @Published var habitNotes = ""
    @Published var priority1 = ""
    @Published var priority2 = ""
    @Published var priority3 = ""
    @Published var shakeTrigger = 0
    @Published var errorMessage = ""

    var isLastStep: Bool {
        currentStep == .priority3
    }

    func next() {
        if let next = WeeklyReviewStep(rawValue: currentStep.rawValue + 1) {
            currentStep = next
        }
    }

    func back() {
        if let prev = WeeklyReviewStep(rawValue: currentStep.rawValue - 1) {
            currentStep = prev
        }
    }
}

struct WeeklyReviewView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = WeeklyReviewViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                VStack(spacing: 0) {
                    progressBar
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    ScrollView {
                        AppCard {
                            stepContent
                        }
                        .padding(AppLayout.padding)
                    }
                    .appScrollChrome()

                    navigationButtons
                        .padding(AppLayout.padding)
                }
            }
            .navigationTitle("Weekly Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        FeedbackManager.lightTap()
                        dismiss()
                    }
                    .foregroundStyle(Color("AppTextSecondary"))
                }
            }
        }
        .appScreenChrome()
    }

    private var progressBar: some View {
        HStack(spacing: 4) {
            ForEach(WeeklyReviewStep.allCases) { step in
                RoundedRectangle(cornerRadius: 2)
                    .fill(step.rawValue <= viewModel.currentStep.rawValue ? Color("AppPrimary") : Color("AppTextSecondary").opacity(0.3))
                    .frame(height: 4)
            }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        Text(viewModel.currentStep.title)
            .font(.title2.bold())
            .foregroundStyle(Color("AppTextPrimary"))

        switch viewModel.currentStep {
        case .welcome:
            welcomeStep
        case .completed:
            completedStep
        case .stuck:
            stuckStep
        case .habits:
            habitsStep
        case .priority1:
            priorityField(text: $viewModel.priority1, placeholder: "Most important goal for next week")
        case .priority2:
            priorityField(text: $viewModel.priority2, placeholder: "Second priority")
        case .priority3:
            priorityField(text: $viewModel.priority3, placeholder: "Third priority")
        }
    }

    private var welcomeStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Take a few minutes to reflect on your week and set clear priorities for the days ahead.")
                .foregroundStyle(Color("AppTextSecondary"))
            HStack(spacing: 16) {
                reviewStat(value: "\(store.tasks.filter(\.completed).count)", label: "Tasks Done")
                reviewStat(value: "\(store.focusSessionsCompleted)", label: "Focus Sessions")
                reviewStat(value: "\(store.longestStreak)", label: "Best Streak")
            }
        }
    }

    private func reviewStat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(Color("AppPrimary"))
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color("AppTextSecondary"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color("AppSurface")))
    }

    private var completedStep: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Celebrate what you accomplished this week.")
                .font(.subheadline)
                .foregroundStyle(Color("AppTextSecondary"))
            let done = store.tasks.filter(\.completed)
            if done.isEmpty {
                Text("No completed tasks yet — a fresh week awaits!")
                    .foregroundStyle(Color("AppTextSecondary"))
            } else {
                ForEach(done.prefix(15)) { task in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color("AppAccent"))
                        Text(task.title)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .padding(10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color("AppSurface")))
                }
            }
        }
    }

    private var stuckStep: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select tasks that didn't move forward this week.")
                .font(.subheadline)
                .foregroundStyle(Color("AppTextSecondary"))
            let open = store.tasks.filter { !$0.completed }
            if open.isEmpty {
                Text("Nothing stuck — great momentum!")
                    .foregroundStyle(Color("AppTextSecondary"))
            } else {
                ForEach(open) { task in
                    Button {
                        FeedbackManager.lightTap()
                        if viewModel.selectedStuckIds.contains(task.id) {
                            viewModel.selectedStuckIds.remove(task.id)
                        } else {
                            viewModel.selectedStuckIds.insert(task.id)
                        }
                    } label: {
                        HStack {
                            Image(systemName: viewModel.selectedStuckIds.contains(task.id) ? "checkmark.square.fill" : "square")
                                .foregroundStyle(Color("AppPrimary"))
                            Text(task.title)
                                .foregroundStyle(Color("AppTextPrimary"))
                                .lineLimit(2)
                                .minimumScaleFactor(0.7)
                            Spacer()
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(viewModel.selectedStuckIds.contains(task.id) ? Color("AppAccent").opacity(0.2) : Color("AppSurface"))
                        )
                    }
                    .buttonStyle(.plain)
                    .frame(minHeight: 44)
                }
            }
        }
    }

    private var habitsStep: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(store.habitsSummaryThisWeek())
                .font(.subheadline)
                .foregroundStyle(Color("AppTextSecondary"))
            Text("Notes on your habits (optional)")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color("AppTextPrimary"))
            TextField("What worked? What to adjust?", text: $viewModel.habitNotes, axis: .vertical)
                .lineLimit(3...6)
                .foregroundStyle(Color("AppTextPrimary"))
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color("AppSurface")))
        }
    }

    private func priorityField(text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Set a clear, actionable priority.")
                .font(.subheadline)
                .foregroundStyle(Color("AppTextSecondary"))
            TextField(placeholder, text: text)
                .foregroundStyle(Color("AppTextPrimary"))
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color("AppSurface")))
                .shake(trigger: viewModel.shakeTrigger)
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    private var navigationButtons: some View {
        HStack(spacing: 12) {
            if viewModel.currentStep != .welcome {
                Button("Back") {
                    FeedbackManager.lightTap()
                    withAnimation(.easeInOut(duration: 0.3)) { viewModel.back() }
                }
                .font(.headline)
                .foregroundStyle(Color("AppTextSecondary"))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: AppLayout.cellRadius).fill(Color("AppSurface")))
                .frame(minHeight: 44)
            }
            AppPrimaryButton(
                title: viewModel.isLastStep ? "Complete Review" : "Next",
                icon: viewModel.isLastStep ? "checkmark" : "arrow.right"
            ) {
                handleNext()
            }
            .frame(maxWidth: viewModel.currentStep == .welcome ? .infinity : nil)
        }
    }

    private func handleNext() {
        FeedbackManager.lightTap()
        if viewModel.currentStep == .priority1 && viewModel.priority1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            viewModel.errorMessage = "Please enter at least your top priority"
            viewModel.shakeTrigger += 1
            FeedbackManager.warning()
            return
        }
        viewModel.errorMessage = ""
        if viewModel.isLastStep {
            let priorities = [
                viewModel.priority1.trimmingCharacters(in: .whitespacesAndNewlines),
                viewModel.priority2.trimmingCharacters(in: .whitespacesAndNewlines),
                viewModel.priority3.trimmingCharacters(in: .whitespacesAndNewlines)
            ].filter { !$0.isEmpty }
            store.saveWeeklyReview(
                stuckTaskIds: Array(viewModel.selectedStuckIds),
                habitNotes: viewModel.habitNotes,
                priorities: priorities
            )
            dismiss()
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                viewModel.next()
            }
        }
    }
}
