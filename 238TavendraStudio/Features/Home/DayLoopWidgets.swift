import SwiftUI

struct ContextConflictBanner: View {
    let conflicts: [ContextConflict]

    var body: some View {
        if !conflicts.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(conflicts) { conflict in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(Color("AppAccent"))
                            .font(.subheadline)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(conflict.title)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(Color("AppTextPrimary"))
                            Text(conflict.message)
                                .font(.caption2)
                                .foregroundStyle(Color("AppTextSecondary"))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color("AppAccent").opacity(0.12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(Color("AppAccent").opacity(0.35), lineWidth: 1)
                            )
                    )
                }
            }
        }
    }
}

struct EnergyForecastCard: View {
    @EnvironmentObject private var store: AppDataStore

    var body: some View {
        AppCard(accent: Color("AppPrimary")) {
            VStack(alignment: .leading, spacing: 14) {
                AppSectionHeader(
                    title: "Energy Forecast",
                    subtitle: "Set expected energy for each block",
                    icon: "bolt.horizontal.fill"
                )
                ForEach(DayBlock.allCases) { block in
                    HStack(spacing: 10) {
                        Image(systemName: block.iconName)
                            .foregroundStyle(Color("AppAccent"))
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(block.rawValue)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(Color("AppTextPrimary"))
                            Text(block.timeRange)
                                .font(.caption2)
                                .foregroundStyle(Color("AppTextSecondary"))
                        }
                        Spacer()
                        energyPicker(for: block)
                    }
                }
            }
        }
        .onAppear { store.ensureTodayForecast() }
    }

    private func energyPicker(for block: DayBlock) -> some View {
        HStack(spacing: 6) {
            ForEach(EnergyLevel.allCases) { level in
                let selected = store.energyForecast.level(for: block) == level
                Button {
                    store.setForecastEnergy(level, for: block)
                } label: {
                    Image(systemName: level.iconName)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(selected ? Color("AppTextPrimary") : Color("AppTextSecondary"))
                        .frame(width: 32, height: 32)
                        .background(
                            Circle().fill(selected ? Color("AppPrimary") : Color("AppBackground").opacity(0.45))
                        )
                }
                .buttonStyle(.plain)
                .frame(minWidth: 44, minHeight: 44)
            }
        }
    }
}

struct NowRecommendationCard: View {
    let recommendation: NowRecommendation
    var onStartFocus: () -> Void
    var onOpenTask: (() -> Void)?

    var body: some View {
        AppCard(accent: Color("AppAccent")) {
            VStack(alignment: .leading, spacing: 14) {
                AppSectionHeader(
                    title: "Do This Now",
                    subtitle: "\(recommendation.block.rawValue) · \(recommendation.forecastEnergy.rawValue) energy",
                    icon: "scope"
                )

                HStack(spacing: 8) {
                    AppChip(text: recommendation.block.rawValue, icon: recommendation.block.iconName, style: .neutral)
                    AppChip(text: recommendation.forecastEnergy.rawValue, icon: recommendation.forecastEnergy.iconName, style: .accent)
                    AppChip(text: recommendation.preferredContext.rawValue, icon: recommendation.preferredContext.iconName, style: .primary)
                }

                if let task = recommendation.task {
                    Button {
                        onOpenTask?()
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(task.title)
                                .font(.title3.bold())
                                .foregroundStyle(Color("AppTextPrimary"))
                                .multilineTextAlignment(.leading)
                            Text(recommendation.reason)
                                .font(.caption)
                                .foregroundStyle(Color("AppTextSecondary"))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(recommendation.reason)
                        .font(.subheadline)
                        .foregroundStyle(Color("AppTextSecondary"))
                }

                ContextConflictBanner(conflicts: recommendation.conflicts)

                AppPrimaryButton(title: "Start Focus", icon: "play.fill", action: onStartFocus)
            }
        }
    }
}

struct TomorrowMustBoardCard: View {
    let tasks: [TaskItem]
    var onToggle: (TaskItem) -> Void
    var onRemove: (UUID) -> Void

    var body: some View {
        AppCard(accent: Color("AppPrimary")) {
            VStack(alignment: .leading, spacing: 12) {
                AppSectionHeader(
                    title: "Tomorrow Must",
                    subtitle: tasks.isEmpty ? "Empty — carry tasks from Evening Review" : "\(tasks.count) committed",
                    icon: "flag.fill",
                    trailing: tasks.isEmpty ? nil : "\(tasks.count)"
                )
                if tasks.isEmpty {
                    Text("Unfinished work you commit to tomorrow appears here — not a plain incomplete list.")
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                } else {
                    ForEach(tasks) { task in
                        HStack(spacing: 10) {
                            AppCheckbox(isOn: task.completed) { onToggle(task) }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(task.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color("AppTextPrimary"))
                                    .lineLimit(2)
                                AppChip(text: task.workContext.rawValue, icon: task.workContext.iconName, style: .accent)
                            }
                            Spacer()
                            Button {
                                onRemove(task.id)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                            .frame(minWidth: 44, minHeight: 44)
                        }
                    }
                }
            }
        }
    }
}

struct DayScoreCard: View {
    let report: DayScoreReport
    var onOpen: (() -> Void)?

    var body: some View {
        Button {
            onOpen?()
        } label: {
            AppCard(accent: Color("AppAccent")) {
                VStack(alignment: .leading, spacing: 14) {
                    AppSectionHeader(
                        title: "Day Score",
                        subtitle: report.gradeLabel,
                        icon: "chart.bar.fill",
                        trailing: "\(report.overallScore)"
                    )
                    HStack(spacing: 10) {
                        scorePill("Blocks", value: "\(Int(report.blockCompletion * 100))%")
                        scorePill("Energy", value: "\(Int(report.energyMatchRate * 100))%")
                        scorePill("Focus", value: "\(report.focusMinutes)m")
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func scorePill(_ label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline.bold())
                .foregroundStyle(Color("AppTextPrimary"))
            Text(label)
                .font(.caption2)
                .foregroundStyle(Color("AppTextSecondary"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .appInsetCell(radius: 12)
    }
}
