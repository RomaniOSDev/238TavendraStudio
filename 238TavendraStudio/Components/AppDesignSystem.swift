import SwiftUI

enum AppLayout {
    static let cardRadius: CGFloat = 18
    static let cellRadius: CGFloat = 14
    static let padding: CGFloat = 16
    static let chipRadius: CGFloat = 8
}

struct AppCard<Content: View>: View {
    var accent: Color?
    @ViewBuilder var content: () -> Content

    var body: some View {
        HStack(spacing: 0) {
            if let accent {
                RoundedRectangle(cornerRadius: 3)
                    .fill(accent)
                    .frame(width: 4)
                    .padding(.vertical, 10)
            }
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AppLayout.padding)
        .padding(.leading, accent == nil ? 0 : -4)
        .appElevatedCard()
    }
}

struct AppSectionHeader: View {
    let title: String
    var subtitle: String?
    var icon: String?
    var trailing: String?

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if let icon {
                AppIconBadge(icon: icon, size: 36, tint: Color("AppPrimary"))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Color("AppTextPrimary"))
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                }
            }
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color("AppAccent"))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color("AppPrimary").opacity(0.35), Color("AppAccent").opacity(0.2)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
        }
    }
}

struct AppIconBadge: View {
    let icon: String
    var size: CGFloat = 40
    var tint: Color = Color("AppPrimary")

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [tint.opacity(0.35), tint.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            Image(systemName: icon)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(tint)
        }
    }
}

struct AppChip: View {
    let text: String
    var icon: String?
    var style: ChipStyle = .neutral

    enum ChipStyle {
        case neutral, primary, accent, high, medium, low

        var background: Color {
            switch self {
            case .neutral: return Color("AppBackground").opacity(0.6)
            case .primary: return Color("AppPrimary").opacity(0.85)
            case .accent: return Color("AppAccent").opacity(0.35)
            case .high: return Color("AppPrimary").opacity(0.85)
            case .medium: return Color("AppAccent").opacity(0.5)
            case .low: return Color("AppSurface")
            }
        }

        var foreground: Color {
            switch self {
            case .neutral: return Color("AppTextSecondary")
            case .low: return Color("AppBackground")
            default: return Color("AppTextPrimary")
            }
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
            }
            Text(text)
                .font(.caption2.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .foregroundStyle(style.foreground)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(
                style == .primary || style == .high
                    ? AnyShapeStyle(AppVisual.buttonGradient)
                    : AnyShapeStyle(style.background)
            )
        )
    }
}

struct AppMetricTile: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            AppIconBadge(icon: icon, size: 32, tint: Color("AppPrimary"))
            Text(value)
                .font(.title2.bold())
                .foregroundStyle(Color("AppTextPrimary"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color("AppTextSecondary"))
                .lineLimit(2)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .appInsetCell()
    }
}

struct AppProgressRing: View {
    let progress: Double
    var size: CGFloat = 48
    var lineWidth: CGFloat = 5

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color("AppTextSecondary").opacity(0.2), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(max(progress, 0), 1))
                .stroke(
                    AppVisual.ringGradient,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)
            Text("\(Int(progress * 100))%")
                .font(.system(size: size * 0.22, weight: .bold))
                .foregroundStyle(Color("AppTextPrimary"))
        }
        .frame(width: size, height: size)
    }
}

struct AppEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color("AppPrimary").opacity(0.28), Color("AppPrimary").opacity(0.06)],
                            center: .center,
                            startRadius: 8,
                            endRadius: 56
                        )
                    )
                    .frame(width: 100, height: 100)
                Image(systemName: icon)
                    .font(.system(size: 44))
                    .foregroundStyle(Color("AppPrimary"))
            }
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(Color("AppTextPrimary"))
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
            }
            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .appGlowButton(radius: 20)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .frame(minHeight: 44)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(32)
    }
}

struct AppPrimaryButton: View {
    let title: String
    var icon: String?
    var isDestructive = false
    let action: () -> Void

  @State private var isPressed = false

    var body: some View {
        Button {
            FeedbackManager.lightTap()
            action()
        } label: {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                        .font(.subheadline.weight(.bold))
                }
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(Color("AppTextPrimary"))
            .frame(maxWidth: .infinity)
            .padding(.horizontal, AppLayout.padding)
            .padding(.vertical, 14)
            .appGlowButton(destructive: isDestructive)
            .scaleEffect(isPressed ? 0.97 : 1)
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeOut(duration: 0.1)) { isPressed = true } }
                .onEnded { _ in withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { isPressed = false } }
        )
    }
}

struct AppFilterBar<Option: Identifiable & Equatable>: View where Option: RawRepresentable, Option.RawValue == String {
    let options: [Option]
    @Binding var selection: Option

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(options) { option in
                    Button {
                        FeedbackManager.lightTap()
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selection = option
                        }
                    } label: {
                        Text(option.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .foregroundStyle(selection == option ? Color("AppTextPrimary") : Color("AppTextSecondary"))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 11)
                            .background(
                                Group {
                                    if selection == option {
                                        Capsule()
                                            .fill(AppVisual.buttonGradient)
                                    } else {
                                        Capsule()
                                            .fill(Color("AppSurface").opacity(0.9))
                                            .overlay(
                                                Capsule()
                                                    .strokeBorder(Color("AppTextSecondary").opacity(0.15), lineWidth: 1)
                                            )
                                    }
                                }
                            )
                            .compositingGroup()
                            .shadow(
                                color: selection == option ? Color("AppPrimary").opacity(0.28) : .clear,
                                radius: 6,
                                y: 2
                            )
                    }
                    .buttonStyle(.plain)
                    .frame(minHeight: 44)
                }
            }
            .padding(.horizontal, AppLayout.padding)
            .padding(.vertical, 10)
        }
        .background(
            LinearGradient(
                colors: [Color("AppBackground").opacity(0.35), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

struct AppCheckbox: View {
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isOn ? Color("AppAccent") : Color("AppTextSecondary").opacity(0.5), lineWidth: 2)
                    .frame(width: 28, height: 28)
                if isOn {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color("AppAccent"))
                        .frame(width: 28, height: 28)
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                }
            }
        }
        .buttonStyle(.plain)
        .frame(minWidth: 44, minHeight: 44)
    }
}

struct SettingsRowCell: View {
    let title: String
    let icon: String
    var isDestructive = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                AppIconBadge(
                    icon: icon,
                    size: 38,
                    tint: isDestructive ? .red : Color("AppPrimary")
                )
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(isDestructive ? .red : Color("AppTextPrimary"))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color("AppTextSecondary"))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(minHeight: 44)
            .appInsetCell()
        }
        .buttonStyle(.plain)
    }
}

struct ActionBannerCell: View {
    let icon: String
    let title: String
    let subtitle: String
    var accent: Color = Color("AppAccent")
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                AppIconBadge(icon: icon, size: 48, tint: accent)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(Color("AppTextSecondary"))
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundStyle(accent)
            }
            .padding(AppLayout.padding)
            .background(
                RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [accent.opacity(0.2), accent.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [accent.opacity(0.55), accent.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .compositingGroup()
            .shadow(color: accent.opacity(0.2), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .frame(minHeight: 44)
    }
}
