import SwiftUI

struct TaskCell: View {
    let task: TaskItem
    var projectName: String?
    var isPulsing = false
    var compact = false
    let onToggle: () -> Void
    var onEdit: (() -> Void)?
    var onMove: ((DayBlock) -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            AppCheckbox(isOn: task.completed, action: onToggle)

            VStack(alignment: .leading, spacing: compact ? 4 : 6) {
                Text(task.title)
                    .font(compact ? .subheadline.weight(.semibold) : .body.weight(.semibold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .strikethrough(task.completed)
                    .lineLimit(compact ? 1 : 2)
                    .minimumScaleFactor(0.7)

                if !compact {
                    FlowChipsRow {
                        AppChip(text: task.priority.rawValue, style: chipStyle(for: task.priority))
                        AppChip(text: task.workContext.rawValue, icon: task.workContext.iconName, style: .accent)
                        if let block = task.dayBlock {
                            AppChip(text: block.rawValue, icon: block.iconName, style: .neutral)
                        }
                        AppChip(text: task.energyLevel.rawValue, icon: task.energyLevel.iconName, style: .neutral)
                        if let projectName {
                            AppChip(text: projectName, icon: "folder.fill", style: .neutral)
                        }
                    }
                } else {
                    HStack(spacing: 6) {
                        AppChip(text: task.workContext.rawValue, icon: task.workContext.iconName, style: .accent)
                        if let projectName {
                            AppChip(text: projectName, icon: "folder.fill", style: .neutral)
                        }
                    }
                }
            }

            Spacer(minLength: 0)

            if let onEdit {
                Button(action: onEdit) {
                    Image(systemName: "square.and.pencil")
                        .font(.body)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color("AppBackground").opacity(0.5)))
                }
                .buttonStyle(.plain)
            } else if onMove != nil {
                Menu {
                    ForEach(DayBlock.allCases) { block in
                        Button("Move to \(block.rawValue)") { onMove?(block) }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(Color("AppTextSecondary"))
                        .frame(width: 36, height: 36)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, compact ? 10 : 14)
        .appInsetCell()
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cellRadius, style: .continuous)
                .strokeBorder(isPulsing ? Color("AppAccent") : Color.clear, lineWidth: 2)
        )
        .pulseHighlight(isPulsing)
    }

    private func chipStyle(for priority: TaskPriority) -> AppChip.ChipStyle {
        switch priority {
        case .high: return .high
        case .medium: return .medium
        case .low: return .low
        }
    }
}

struct HabitCell: View {
    let habit: Habit
    var isStreakEnlarged = false
    let onToggle: () -> Void

    var body: some View {
        let done = habit.isCompletedToday()
        HStack(spacing: 14) {
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .stroke(done ? Color("AppAccent") : Color("AppTextSecondary").opacity(0.4), lineWidth: 2.5)
                        .frame(width: 32, height: 32)
                    if done {
                        Circle().fill(Color("AppAccent")).frame(width: 32, height: 32)
                        Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                    }
                }
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)

            VStack(alignment: .leading, spacing: 6) {
                Text(habit.title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                HStack(spacing: 6) {
                    AppChip(text: habit.preferredDayBlock.rawValue, icon: habit.preferredDayBlock.iconName, style: .neutral)
                    if done {
                        AppChip(text: "Done today", icon: "checkmark", style: .accent)
                    }
                }
            }

            Spacer()

            VStack(spacing: 2) {
                HStack(spacing: 3) {
                    Image(systemName: "flame.fill")
                        .font(.caption)
                    Text("\(habit.streak)")
                        .font(.title3.weight(.bold))
                }
                .foregroundStyle(Color("AppPrimary"))
                .scaleEffect(isStreakEnlarged ? 1.35 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.55), value: isStreakEnlarged)
                Text("streak")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
            }
        }
        .padding(14)
        .appInsetCell()
    }
}

struct ProjectCell: View {
    let project: Project
    let progress: Double
    let taskCount: Int
    let sessionCount: Int

    var body: some View {
        HStack(spacing: 14) {
            AppProgressRing(progress: progress, size: 52, lineWidth: 5)
            VStack(alignment: .leading, spacing: 6) {
                Text(project.name)
                    .font(.body.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                HStack(spacing: 10) {
                    Label("\(taskCount) tasks", systemImage: "checklist")
                    Label("\(sessionCount) sessions", systemImage: "timer")
                }
                .font(.caption)
                .foregroundStyle(Color("AppTextSecondary"))
                if let deadline = project.deadline {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.caption2)
                        Text(deadline, style: .date)
                            .font(.caption2.weight(.semibold))
                    }
                    .foregroundStyle(Color("AppAccent"))
                }
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .padding(14)
        .appInsetCell()
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cellRadius, style: .continuous)
                .strokeBorder(Color("AppPrimary").opacity(0.22), lineWidth: 1)
        )
    }
}

struct FocusSessionCell: View {
    let session: FocusSessionRecord
    var projectName: String?

    var body: some View {
        HStack(spacing: 12) {
            AppIconBadge(
                icon: session.type == .work ? (session.workContext?.iconName ?? "timer") : "cup.and.saucer.fill",
                size: 40,
                tint: session.type == .work ? Color("AppPrimary") : Color("AppAccent")
            )
            VStack(alignment: .leading, spacing: 4) {
                Text(session.type == .work ? (session.workContext?.rawValue ?? "Work") : "Break")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                Text(timeRange)
                    .font(.caption)
                    .foregroundStyle(Color("AppTextSecondary"))
                if let projectName {
                    AppChip(text: projectName, icon: "folder.fill", style: .neutral)
                }
            }
            Spacer()
            if let block = session.dayBlock {
                AppChip(text: block.rawValue, icon: block.iconName, style: .neutral)
            }
        }
        .padding(12)
        .appInsetCell()
    }

    private var timeRange: String {
        let f = DateFormatter()
        f.timeStyle = .short
        return "\(f.string(from: session.startDate)) – \(f.string(from: session.endDate))"
    }
}

struct ContextCardCell: View {
    let context: WorkContext
    let durationMin: Int
    let sessionCount: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                AppIconBadge(
                    icon: context.iconName,
                    size: 44,
                    tint: isSelected ? Color("AppPrimary") : Color("AppTextSecondary")
                )
                Text(context.rawValue)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isSelected ? Color("AppTextPrimary") : Color("AppTextSecondary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("\(durationMin)m")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color("AppAccent"))
                Text("\(sessionCount)")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(Color("AppTextSecondary"))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color("AppBackground").opacity(0.5)))
            }
            .frame(width: 88)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: AppLayout.cellRadius, style: .continuous)
                            .fill(AppVisual.buttonGradient)
                    } else {
                        RoundedRectangle(cornerRadius: AppLayout.cellRadius, style: .continuous)
                            .fill(AppVisual.cellGradient)
                            .overlay(
                                RoundedRectangle(cornerRadius: AppLayout.cellRadius, style: .continuous)
                                    .strokeBorder(Color("AppTextSecondary").opacity(0.12), lineWidth: 1)
                            )
                    }
                }
            )
            .compositingGroup()
            .shadow(color: isSelected ? Color("AppPrimary").opacity(0.3) : .clear, radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
    }
}

struct AchievementCell: View {
    let achievement: AchievementDefinition
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(
                        isUnlocked
                            ? LinearGradient(colors: [Color("AppPrimary"), Color("AppAccent")], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color("AppSurface"), Color("AppBackground").opacity(0.5)], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 54, height: 54)
                Image(systemName: achievement.iconName)
                    .font(.title3)
                    .foregroundStyle(isUnlocked ? Color("AppTextPrimary") : Color("AppTextSecondary").opacity(0.4))
            }
            Text(achievement.title)
                .font(.caption.weight(.bold))
                .foregroundStyle(isUnlocked ? Color("AppTextPrimary") : Color("AppTextSecondary"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            Text(achievement.description)
                .font(.caption2)
                .foregroundStyle(Color("AppTextSecondary"))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 150)
        .appElevatedCard()
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cellRadius, style: .continuous)
                .strokeBorder(isUnlocked ? Color("AppAccent").opacity(0.5) : .clear, lineWidth: 1.5)
        )
        .opacity(isUnlocked ? 1 : 0.75)
    }
}

struct DayBlockCard: View {
    let block: DayBlock
    let taskCount: Int
    let habitCount: Int
    let onAdd: () -> Void
    let onFocus: () -> Void
    @ViewBuilder var content: () -> AnyView

    init(
        block: DayBlock,
        taskCount: Int,
        habitCount: Int,
        onAdd: @escaping () -> Void,
        onFocus: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> some View
    ) {
        self.block = block
        self.taskCount = taskCount
        self.habitCount = habitCount
        self.onAdd = onAdd
        self.onFocus = onFocus
        self.content = { AnyView(content()) }
    }

    var body: some View {
        AppCard(accent: Color("AppPrimary")) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    AppSectionHeader(
                        title: block.rawValue,
                        subtitle: block.timeRange,
                        icon: block.iconName,
                        trailing: "\(taskCount) tasks"
                    )
                    Button(action: onAdd) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(Color("AppAccent"))
                    }
                    .frame(minWidth: 44, minHeight: 44)
                }

                if habitCount > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.caption)
                            .foregroundStyle(Color("AppPrimary"))
                        Text("\(habitCount) habit\(habitCount == 1 ? "" : "s") in this block")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color("AppTextSecondary"))
                    }
                }

                content()

                AppPrimaryButton(title: "Start Focus", icon: "play.fill", action: onFocus)
            }
        }
    }
}

struct FlowChipsRow<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                content()
            }
        }
    }
}

struct FocusTimerDisplay: View {
    let label: String
    let timeText: String
    let isRunning: Bool
    var progress: Double = 0

    var body: some View {
        VStack(spacing: 16) {
            Text(label)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color("AppTextSecondary"))
                .textCase(.uppercase)
                .tracking(1.2)

            ZStack {
                Circle()
                    .stroke(Color("AppTextSecondary").opacity(0.15), lineWidth: 8)
                    .frame(width: 200, height: 200)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AppVisual.ringGradient,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 200, height: 200)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 4) {
                    Text(timeText)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    if isRunning {
                        HStack(spacing: 4) {
                            Circle().fill(Color("AppAccent")).frame(width: 6, height: 6)
                            Text("In progress")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color("AppAccent"))
                        }
                    }
                }
            }

        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}
