import SwiftUI

enum HomeQuickAction: String, CaseIterable, Identifiable {
    case addTask
    case startFocus
    case addHabit
    case dayPlan
    case eveningReview

    var id: String { rawValue }

    var title: String {
        switch self {
        case .addTask: return "Add Task"
        case .startFocus: return "Focus"
        case .addHabit: return "Habit"
        case .dayPlan: return "Day Plan"
        case .eveningReview: return "Review"
        }
    }

    var icon: String {
        switch self {
        case .addTask: return "plus.circle.fill"
        case .startFocus: return "play.circle.fill"
        case .addHabit: return "flame.fill"
        case .dayPlan: return "calendar"
        case .eveningReview: return "moon.stars.fill"
        }
    }
}

struct HomeWidgetCard<Content: View>: View {
    var title: String
    var subtitle: String?
    var imageName: String?
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption2)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                }
                Spacer(minLength: 0)
                if let imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 52, height: 52)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color("AppPrimary").opacity(0.3), lineWidth: 1)
                        )
                }
            }
            content()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appElevatedCard()
    }
}

struct HomeQuickActionButton: View {
    let action: HomeQuickAction
    let onTap: () -> Void

    var body: some View {
        Button {
            FeedbackManager.lightTap()
            onTap()
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color("AppPrimary").opacity(0.28), Color("AppAccent").opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                    Image(systemName: action.icon)
                        .font(.title3)
                        .foregroundStyle(Color("AppPrimary"))
                }
                Text(action.title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .appInsetCell()
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
    }
}

struct HomeProgressWidget: View {
    let progress: Double
    let openTasks: Int
    let completedToday: Int
    let focusSessions: Int
    let streak: Int

    var body: some View {
        HomeWidgetCard(title: "Today at a Glance", subtitle: "Your daily snapshot") {
            HStack(spacing: 16) {
                AppProgressRing(progress: progress, size: 72, lineWidth: 7)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    miniMetric("\(openTasks)", label: "Open", icon: "circle")
                    miniMetric("\(completedToday)", label: "Done", icon: "checkmark")
                    miniMetric("\(focusSessions)", label: "Focus", icon: "timer")
                    miniMetric("\(streak)d", label: "Streak", icon: "flame")
                }
            }
        }
    }

    private func miniMetric(_ value: String, label: String, icon: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundStyle(Color("AppAccent"))
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color("AppTextSecondary"))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(AppVisual.cellGradient)
        )
    }
}

struct HomeFocusWidget: View {
    @EnvironmentObject private var store: AppDataStore
    let onStart: () -> Void

    var body: some View {
        HomeWidgetCard(title: "Focus Session", subtitle: store.activeFocusContext.rawValue, imageName: "widget_focus") {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let remaining = store.displayRemainingSeconds(at: context.date)
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(store.timerIsRunning ? "In progress" : "Ready to start")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(store.timerIsRunning ? Color("AppAccent") : Color("AppTextSecondary"))
                        Text(formatTime(remaining))
                            .font(.title2.bold().monospacedDigit())
                            .foregroundStyle(Color("AppTextPrimary"))
                    }
                    Spacer()
                    Button(action: onStart) {
                        Image(systemName: store.timerIsRunning ? "stop.fill" : "play.fill")
                            .font(.title2)
                            .foregroundStyle(Color("AppTextPrimary"))
                            .frame(width: 48, height: 48)
                            .background(Circle().fill(Color("AppPrimary")))
                    }
                    .buttonStyle(.plain)
                    .frame(minWidth: 44, minHeight: 44)
                }
            }
        }
    }

    private func formatTime(_ seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

struct HomeTasksWidget: View {
    let tasks: [TaskItem]
    let onTaskTap: (TaskItem) -> Void
    let onSeeAll: () -> Void

    var body: some View {
        HomeWidgetCard(title: "Up Next", subtitle: "\(tasks.count) pending tasks", imageName: "widget_tasks") {
            if tasks.isEmpty {
                Text("No pending tasks — add one to get started")
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            } else {
                VStack(spacing: 8) {
                    ForEach(tasks.prefix(3)) { task in
                        Button { onTaskTap(task) } label: {
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(Color("AppPrimary").opacity(0.25))
                                    .frame(width: 8, height: 8)
                                Text(task.title)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color("AppTextPrimary"))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                Spacer()
                                AppChip(text: task.priority.rawValue, style: priorityStyle(task.priority))
                            }
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Button("See All Tasks", action: onSeeAll)
                .font(.caption.weight(.bold))
                .foregroundStyle(Color("AppPrimary"))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .frame(minHeight: 44)
        }
    }

    private func priorityStyle(_ p: TaskPriority) -> AppChip.ChipStyle {
        switch p {
        case .high: return .high
        case .medium: return .medium
        case .low: return .low
        }
    }
}

struct HomeHabitsWidget: View {
    let habits: [Habit]
    let onToggle: (Habit) -> Void

    var body: some View {
        let done = habits.filter { $0.isCompletedToday() }.count
        HomeWidgetCard(title: "Daily Routines", subtitle: "\(done)/\(habits.count) done today", imageName: "widget_habits") {
            if habits.isEmpty {
                Text("Create a habit to build your routine")
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
            } else {
                VStack(spacing: 8) {
                    ForEach(habits.prefix(4)) { habit in
                        Button { onToggle(habit) } label: {
                            HStack {
                                Image(systemName: habit.isCompletedToday() ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(habit.isCompletedToday() ? Color("AppAccent") : Color("AppTextSecondary"))
                                Text(habit.title)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color("AppTextPrimary"))
                                    .lineLimit(1)
                                Spacer()
                                HStack(spacing: 2) {
                                    Image(systemName: "flame.fill").font(.caption2)
                                    Text("\(habit.streak)").font(.caption2.weight(.bold))
                                }
                                .foregroundStyle(Color("AppPrimary"))
                            }
                        }
                        .buttonStyle(.plain)
                        .frame(minHeight: 36)
                    }
                }
            }
        }
    }
}

struct HomeEnergyWidget: View {
    @Binding var selection: EnergyLevel
    let onSelect: (EnergyLevel) -> Void

    var body: some View {
        HomeWidgetCard(title: "Energy Level", subtitle: "Match tasks to how you feel") {
            EnergyLevelPicker(selection: $selection, onSelect: onSelect)
        }
    }
}

struct HomePrioritiesWidget: View {
    let priorities: [String]

    var body: some View {
        HomeWidgetCard(title: "Week Priorities", subtitle: "From your last review") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(priorities.prefix(3).enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 10) {
                        Text("\(index + 1)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(Color("AppPrimary")))
                        Text(item)
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            }
        }
    }
}
