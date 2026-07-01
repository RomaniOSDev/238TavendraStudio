import SwiftUI

struct EnergyLevelPicker: View {
    @Binding var selection: EnergyLevel
    var onSelect: ((EnergyLevel) -> Void)?

    var body: some View {
        HStack(spacing: 10) {
            ForEach(EnergyLevel.allCases) { level in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selection = level
                    }
                    onSelect?(level)
                } label: {
                    VStack(spacing: 6) {
                        AppIconBadge(
                            icon: level.iconName,
                            size: 36,
                            tint: selection == level ? Color("AppPrimary") : Color("AppTextSecondary")
                        )
                        Text(level.rawValue)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(selection == level ? Color("AppTextPrimary") : Color("AppTextSecondary"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: AppLayout.cellRadius)
                            .fill(selection == level ? Color("AppPrimary").opacity(0.85) : Color("AppBackground").opacity(0.4))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppLayout.cellRadius)
                                    .stroke(selection == level ? Color("AppAccent") : .clear, lineWidth: 1.5)
                            )
                    )
                }
                .buttonStyle(.plain)
                .frame(minHeight: 44)
            }
        }
    }
}

struct EnergyStatsCard: View {
    @EnvironmentObject private var store: AppDataStore

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                AppSectionHeader(title: "Energy Patterns", subtitle: "When you feel most productive", icon: "chart.line.uptrend.xyaxis")
                let maxCount = store.energyProductivityStats().map(\.count).max() ?? 1
                ForEach(store.energyProductivityStats(), id: \.level.id) { item in
                    HStack(spacing: 12) {
                        AppIconBadge(icon: item.level.iconName, size: 30, tint: Color("AppPrimary"))
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.level.rawValue)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color("AppTextPrimary"))
                                Spacer()
                                Text("\(item.count)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(Color("AppTextSecondary"))
                            }
                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color("AppPrimary").opacity(0.25))
                                    .frame(height: 6)
                                    .overlay(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(Color("AppPrimary"))
                                            .frame(width: maxCount > 0 ? geo.size.width * CGFloat(item.count) / CGFloat(maxCount) : 0, height: 6)
                                    }
                            }
                            .frame(height: 6)
                        }
                    }
                }
                if store.energyLogs.isEmpty {
                    Text("Log your energy on the Today tab to see patterns.")
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
        }
    }
}
