import SwiftUI

struct LoadingHeroCard: View {
    var height: CGFloat = 150

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image("onboarding_energy")
                .resizable()
                .scaledToFill()
                .frame(height: height)
                .frame(maxWidth: .infinity)
                .clipped()

            LinearGradient(
                colors: [.clear, Color("AppBackground").opacity(0.92)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 4) {
                Text("Day OS")
                    .font(.title2.bold())
                    .foregroundStyle(Color("AppTextPrimary"))
                Text("Energy × Blocks × Context")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color("AppAccent"))
            }
            .padding(AppLayout.padding)
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppLayout.cardRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color("AppPrimary").opacity(0.4), Color("AppAccent").opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .compositingGroup()
        .shadow(color: .black.opacity(0.18), radius: 12, y: 6)
    }
}

struct LoadingScoreRing: View {
    @State private var orbit = false
    @State private var fill = false

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color("AppSurface"), lineWidth: 12)

            Circle()
                .trim(from: 0, to: fill ? 0.86 : 0.12)
                .stroke(AppVisual.ringGradient, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Circle()
                .trim(from: 0, to: 0.18)
                .stroke(
                    Color("AppTextPrimary").opacity(0.35),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                )
                .padding(-14)
                .rotationEffect(.degrees(orbit ? 360 : 0))

            Circle()
                .fill(AppVisual.cardGradient)
                .padding(18)
                .overlay(
                    Circle()
                        .strokeBorder(Color("AppTextPrimary").opacity(0.1), lineWidth: 1)
                        .padding(18)
                )

            VStack(spacing: 4) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(AppVisual.buttonGradient)
                Text("SYNC")
                    .font(.caption2.weight(.heavy))
                    .tracking(2)
                    .foregroundStyle(Color("AppTextSecondary"))
            }
        }
        .frame(width: 150, height: 150)
        .onAppear {
            withAnimation(.linear(duration: 4).repeatForever(autoreverses: false)) {
                orbit = true
            }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                fill = true
            }
        }
    }
}

struct LoadingStepRow: View {
    let icon: String
    let title: String
    let isDone: Bool
    let isActive: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isDone || isActive ? AnyShapeStyle(AppVisual.buttonGradient) : AnyShapeStyle(Color("AppSurface")))
                    .frame(width: 36, height: 36)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color("AppTextPrimary").opacity(0.12), lineWidth: 1)
                    )
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color("AppTextPrimary"))
            }

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isDone || isActive ? Color("AppTextPrimary") : Color("AppTextSecondary"))

            Spacer(minLength: 0)

            Image(systemName: isDone ? "checkmark.circle.fill" : "circle.dotted")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(isDone ? Color("AppAccent") : Color("AppTextSecondary").opacity(0.6))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .appInsetCell()
        .appAccentStripe(isActive ? Color("AppAccent") : .clear)
    }
}

struct LoadingProgressBar: View {
    let progress: CGFloat

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color("AppSurface"))
                Capsule()
                    .fill(AppVisual.buttonGradient)
                    .frame(width: max(geo.size.width * progress, 12))
            }
        }
        .frame(height: 6)
    }
}

struct LoadingView: View {
    @State private var appeared = false
    @State private var step = 0

    private let steps: [(icon: String, title: String)] = [
        ("bolt.heart.fill", "Reading your energy"),
        ("square.grid.3x2.fill", "Aligning time blocks"),
        ("scope", "Applying context rules")
    ]

    var body: some View {
        ZStack {
            AppBackgroundView()

            GeometryReader { geo in
                if geo.size.width > geo.size.height {
                    HStack(spacing: 24) {
                        VStack(spacing: 18) {
                            heroCard(height: 110)
                            scoreRing
                                .scaleEffect(0.8)
                        }
                        .frame(maxWidth: .infinity)

                        VStack(spacing: 18) {
                            stepsCard
                            progressBar
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 64)
                    .padding(.vertical, 24)
                    .frame(width: geo.size.width, height: geo.size.height)
                } else {
                    VStack(spacing: 22) {
                        Spacer(minLength: 0)
                        heroCard(height: 150)
                        scoreRing
                            .padding(.vertical, 8)
                        stepsCard
                        progressBar
                            .padding(.horizontal, 20)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 20)
                    .frame(width: geo.size.width, height: geo.size.height)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.82)) {
                appeared = true
            }
        }
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_100_000_000)
                guard !Task.isCancelled else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    step = (step + 1) % (steps.count + 1)
                }
            }
        }
    }

    private func heroCard(height: CGFloat) -> some View {
        LoadingHeroCard(height: height)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : -16)
    }

    private var scoreRing: some View {
        LoadingScoreRing()
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.9)
    }

    private var stepsCard: some View {
        VStack(spacing: 10) {
            ForEach(steps.indices, id: \.self) { index in
                LoadingStepRow(
                    icon: steps[index].icon,
                    title: steps[index].title,
                    isDone: index < step,
                    isActive: index == step
                )
            }
        }
        .padding(AppLayout.padding)
        .appElevatedCard()
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
    }

    private var progressBar: some View {
        LoadingProgressBar(progress: CGFloat(step + 1) / CGFloat(steps.count + 1))
            .opacity(appeared ? 1 : 0)
    }
}

#Preview {
    LoadingView()
}
