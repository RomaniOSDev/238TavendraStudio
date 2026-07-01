import Combine
import SwiftUI

@MainActor
final class HabitsViewModel: ObservableObject {
    @Published var showAddSheet = false
    @Published var editingHabit: Habit?
    @Published var enlargedStreakID: UUID?

    func openAdd() {
        FeedbackManager.lightTap()
        editingHabit = nil
        showAddSheet = true
    }

    func openEdit(_ habit: Habit) {
        FeedbackManager.lightTap()
        editingHabit = habit
        showAddSheet = true
    }

    func triggerStreakAnimation(for habitID: UUID) {
        enlargedStreakID = habitID
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.enlargedStreakID = nil }
    }
}

struct HabitsView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = HabitsViewModel()

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                if store.habits.isEmpty {
                    ScrollView {
                        AppEmptyState(
                            icon: "sun.max.fill",
                            title: "Track what matters — create your first habit!",
                            message: "No habits yet - tap + to start building your routine!",
                            actionTitle: "Add Habit",
                            action: { viewModel.openAdd() }
                        )
                    }
                    .appScrollChrome()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            habitsSummary
                            ForEach(store.habits) { habit in
                                HabitCell(
                                    habit: habit,
                                    isStreakEnlarged: viewModel.enlargedStreakID == habit.id,
                                    onToggle: {
                                        let wasIncomplete = !habit.isCompletedToday()
                                        store.toggleHabitToday(habit)
                                        if wasIncomplete { viewModel.triggerStreakAnimation(for: habit.id) }
                                    }
                                )
                                .contextMenu {
                                    Button { viewModel.openEdit(habit) } label: { Label("Edit", systemImage: "pencil") }
                                    Button(role: .destructive) { store.deleteHabit(habit) } label: { Label("Delete", systemImage: "trash") }
                                }
                            }
                            Spacer(minLength: 90)
                        }
                        .padding(AppLayout.padding)
                    }
                    .appScrollChrome()
                }
            }

            AppPrimaryButton(title: "Add Habit", icon: "plus", action: { viewModel.openAdd() })
                .padding(.horizontal, AppLayout.padding)
                .padding(.bottom, 16)
        }
        .navigationTitle("Daily Routines")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { viewModel.openAdd() } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(Color("AppPrimary"))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color("AppSurface")))
                }
            }
        }
        .sheet(isPresented: $viewModel.showAddSheet) {
            HabitFormView(habit: viewModel.editingHabit).environmentObject(store)
        }
    }

    private var habitsSummary: some View {
        AppCard {
            HStack(spacing: 16) {
                AppMetricTile(
                    icon: "flame.fill",
                    value: "\(store.habits.map(\.streak).max() ?? 0)",
                    label: "Best Streak"
                )
                AppMetricTile(
                    icon: "checkmark.circle.fill",
                    value: "\(store.habits.filter { $0.isCompletedToday() }.count)/\(store.habits.count)",
                    label: "Done Today"
                )
            }
        }
    }
}

struct HabitFormView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    let habit: Habit?

    @State private var title = ""
    @State private var preferredBlock: DayBlock = .morning
    @State private var shakeTrigger = 0
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Habit Name").font(.caption.weight(.bold)).foregroundStyle(Color("AppTextSecondary"))
                        TextField("e.g. Morning meditation", text: $title)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .padding(14)
                            .background(RoundedRectangle(cornerRadius: AppLayout.cellRadius).fill(Color("AppSurface")))
                            .shake(trigger: shakeTrigger)
                    }
                    if !errorMessage.isEmpty {
                        Text(errorMessage).font(.caption).foregroundStyle(.red)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Best Time Block").font(.caption.weight(.bold)).foregroundStyle(Color("AppTextSecondary"))
                        Picker("Block", selection: $preferredBlock) {
                            ForEach(DayBlock.allCases) { block in
                                Label(block.rawValue, systemImage: block.iconName).tag(block)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    Spacer()
                }
                .padding(AppLayout.padding)
            }
            .navigationTitle(habit == nil ? "New Habit" : "Edit Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { FeedbackManager.lightTap(); dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveHabit() }.foregroundStyle(Color("AppPrimary"))
                }
            }
            .onAppear {
                title = habit?.title ?? ""
                preferredBlock = habit?.preferredDayBlock ?? .morning
            }
        }
        .presentationDetents([.medium])
    }

    private func saveHabit() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Please enter a habit name"
            shakeTrigger += 1
            FeedbackManager.warning()
            return
        }
        if var existing = habit {
            existing.title = trimmed
            existing.preferredDayBlock = preferredBlock
            store.updateHabit(existing)
            FeedbackManager.success()
        } else {
            store.addHabit(title: trimmed, preferredDayBlock: preferredBlock)
        }
        dismiss()
    }
}
