import SwiftUI

private struct OnboardingPage: Identifiable {
    let id: Int
    let icon: String
    let headline: String
    let description: String
    let highlights: [String]
    let imageName: String?
    let accent: Color

    static let all: [OnboardingPage] = [
        OnboardingPage(
            id: 0,
            icon: "bolt.horizontal.fill",
            headline: "Energy Forecast",
            description: "Set High / Medium / Low energy for Morning, Afternoon and Evening — then the app recommends what to do now.",
            highlights: ["Per-block energy", "Do This Now", "Context Rules"],
            imageName: "onboarding_energy",
            accent: Color("AppPrimary")
        ),
        OnboardingPage(
            id: 1,
            icon: "scope",
            headline: "Context-Aware Focus",
            description: "Deep Work belongs in Morning with High energy. Conflicts surface when context, block and energy disagree.",
            highlights: ["Deep Work rules", "Focus durations", "Smart conflicts"],
            imageName: "widget_focus",
            accent: Color("AppAccent")
        ),
        OnboardingPage(
            id: 2,
            icon: "flag.fill",
            headline: "Day Score & Tomorrow Must",
            description: "Evening Review commits unfinished work to Tomorrow Must and locks a Day Score from blocks, energy match and focus minutes.",
            highlights: ["Day Score", "Tomorrow Must", "Weekly Priorities"],
            imageName: "widget_habits",
            accent: Color("AppPrimary")
        )
    ]
}

struct OnboardingView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var currentPage = 0
    @State private var contentScale: CGFloat = 0.92
    @State private var contentOpacity: Double = 0

    private var page: OnboardingPage { OnboardingPage.all[currentPage] }
    private var isLastPage: Bool { currentPage == OnboardingPage.all.count - 1 }

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, AppLayout.padding)
                    .padding(.top, 12)

                TabView(selection: $currentPage) {
                    ForEach(OnboardingPage.all) { item in
                        pageContent(item)
                            .tag(item.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)

                bottomPanel
            }
        }
        .onChange(of: currentPage) { _ in animateContent() }
        .onAppear { animateContent() }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            AppChip(
                text: "\(currentPage + 1) of \(OnboardingPage.all.count)",
                icon: "circle.grid.2x2",
                style: .neutral
            )
            Spacer()
            if !isLastPage {
                Button("Skip") {
                    FeedbackManager.lightTap()
                    store.completeOnboarding()
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color("AppTextSecondary"))
                .frame(minHeight: 44)
            }
        }
    }

    // MARK: - Page content

    private func pageContent(_ item: OnboardingPage) -> some View {
        VStack(spacing: 24) {
            Spacer(minLength: 8)

            illustrationCard(for: item)
                .scaleEffect(contentScale)
                .opacity(contentOpacity)

            VStack(spacing: 14) {
                AppIconBadge(icon: item.icon, size: 52, tint: item.accent)

                Text(item.headline)
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color("AppTextPrimary"))
                    .multilineTextAlignment(.center)

                Text(item.description)
                    .font(.body)
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.horizontal, 8)

                highlightsRow(item.highlights, accent: item.accent)
            }
            .scaleEffect(contentScale)
            .opacity(contentOpacity)

            Spacer(minLength: 16)
        }
        .padding(.horizontal, AppLayout.padding)
    }

    private func illustrationCard(for item: OnboardingPage) -> some View {
        ZStack(alignment: .bottomLeading) {
            if let imageName = item.imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
                    .clipped()
            } else {
                OnboardingFeatureIllustration(pageID: item.id, accent: item.accent)
                    .frame(height: 220)
                    .frame(maxWidth: .infinity)
            }

            LinearGradient(
                colors: [.clear, Color("AppBackground").opacity(0.75)],
                startPoint: .center,
                endPoint: .bottom
            )

            HStack(spacing: 6) {
                Image(systemName: item.icon)
                    .font(.caption.weight(.bold))
                Text(item.highlights.first ?? "")
                    .font(.caption.weight(.semibold))
                    .lineLimit(1)
            }
            .foregroundStyle(Color("AppTextPrimary"))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(item.accent.opacity(0.35))
                    .overlay(Capsule().strokeBorder(item.accent.opacity(0.5), lineWidth: 1))
            )
            .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [item.accent.opacity(0.45), item.accent.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .compositingGroup()
        .shadow(color: item.accent.opacity(0.22), radius: 12, y: 6)
    }

    private func highlightsRow(_ highlights: [String], accent: Color) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(highlights, id: \.self) { text in
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(accent)
                        Text(text)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color("AppTextPrimary"))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .appInsetCell(radius: 20)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: - Bottom panel

    private var bottomPanel: some View {
        VStack(spacing: 20) {
            HStack(spacing: 8) {
                ForEach(OnboardingPage.all) { item in
                    Capsule()
                        .fill(
                            item.id == currentPage
                                ? AnyShapeStyle(AppVisual.buttonGradient)
                                : AnyShapeStyle(Color("AppTextSecondary").opacity(0.25))
                        )
                        .frame(width: item.id == currentPage ? 28 : 8, height: 8)
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: currentPage)
                }
            }

            HStack(spacing: 12) {
                if currentPage > 0 {
                    Button {
                        FeedbackManager.lightTap()
                        withAnimation(.easeInOut(duration: 0.3)) { currentPage -= 1 }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.headline.weight(.bold))
                            .foregroundStyle(Color("AppTextPrimary"))
                            .frame(width: 52, height: 52)
                            .appInsetCell(radius: 16)
                    }
                    .buttonStyle(.plain)
                }

                AppPrimaryButton(
                    title: isLastPage ? "Get Started" : "Continue",
                    icon: isLastPage ? "arrow.right" : "chevron.right"
                ) {
                    if isLastPage {
                        store.completeOnboarding()
                    } else {
                        withAnimation(.easeInOut(duration: 0.3)) { currentPage += 1 }
                    }
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 36)
        .background(
            LinearGradient(
                colors: [
                    Color("AppBackground").opacity(0),
                    Color("AppBackground").opacity(0.92),
                    Color("AppSurface").opacity(0.85)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private func animateContent() {
        contentScale = 0.92
        contentOpacity = 0
        withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
            contentScale = 1
            contentOpacity = 1
        }
    }
}

// MARK: - Fallback illustration (no image asset)

private struct OnboardingFeatureIllustration: View {
    let pageID: Int
    let accent: Color

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [accent.opacity(0.18), Color("AppSurface").opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            switch pageID {
            case 0: dayPlanGraphic
            case 1: focusGraphic
            default: habitsGraphic
            }
        }
    }

    private var dayPlanGraphic: some View {
        HStack(spacing: 10) {
            ForEach(["sunrise.fill", "sun.max.fill", "moon.stars.fill"], id: \.self) { icon in
                VStack(spacing: 8) {
                    AppIconBadge(icon: icon, size: 44, tint: accent)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppVisual.cellGradient)
                        .frame(width: 56, height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(accent.opacity(0.35))
                        .frame(width: 40, height: 8)
                }
                .padding(12)
                .appInsetCell()
            }
        }
    }

    private var focusGraphic: some View {
        ZStack {
            Circle()
                .stroke(Color("AppTextSecondary").opacity(0.15), lineWidth: 6)
                .frame(width: 120, height: 120)
            Circle()
                .trim(from: 0, to: 0.72)
                .stroke(AppVisual.ringGradient, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
            Text("25:00")
                .font(.title2.bold().monospacedDigit())
                .foregroundStyle(Color("AppTextPrimary"))
        }
    }

    private var habitsGraphic: some View {
        VStack(spacing: 10) {
            ForEach(0..<3, id: \.self) { index in
                HStack(spacing: 10) {
                    Circle()
                        .fill(index == 0 ? accent : Color("AppTextSecondary").opacity(0.2))
                        .frame(width: 22, height: 22)
                        .overlay {
                            if index == 0 {
                                Image(systemName: "checkmark")
                                    .font(.caption2.bold())
                                    .foregroundStyle(Color("AppTextPrimary"))
                            }
                        }
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(AppVisual.cellGradient)
                        .frame(width: CGFloat(100 + index * 24), height: 12)
                    Spacer()
                }
            }
            .padding(.horizontal, 28)
        }
    }
}
