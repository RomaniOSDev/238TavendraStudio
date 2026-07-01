import SwiftUI

// MARK: - Optimized visual tokens
// Rules: one shadow per layer, compositingGroup before shadow, no blur, no animated shadow radius.

enum AppVisual {
    static let cardRadius = AppLayout.cardRadius
    static let cellRadius = AppLayout.cellRadius

    static var cardGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color("AppSurface"),
                Color("AppSurface").opacity(0.78),
                Color("AppBackground").opacity(0.45)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var cellGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color("AppSurface").opacity(0.95),
                Color("AppSurface").opacity(0.7),
                Color("AppBackground").opacity(0.35)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var buttonGradient: LinearGradient {
        LinearGradient(
            colors: [Color("AppPrimary"), Color("AppAccent").opacity(0.88)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var ringGradient: AngularGradient {
        AngularGradient(
            colors: [Color("AppPrimary"), Color("AppAccent"), Color("AppPrimary")],
            center: .center
        )
    }
}

// MARK: - Reusable shape backgrounds (rasterized once via compositingGroup on parent)

struct AppCardBackground: View {
    var radius: CGFloat = AppVisual.cardRadius
    var style: Style = .elevated

    enum Style {
        case elevated, inset, glass
    }

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(fillGradient)
            .overlay(highlightStroke)
    }

    private var fillGradient: LinearGradient {
        switch style {
        case .elevated, .glass:
            return AppVisual.cardGradient
        case .inset:
            return AppVisual.cellGradient
        }
    }

    private var highlightStroke: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color("AppTextPrimary").opacity(style == .glass ? 0.18 : 0.12),
                        Color("AppTextPrimary").opacity(0.03)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}

// MARK: - View modifiers

extension View {
    /// Card-level elevation — use on sections/widgets, NOT on every list row.
    func appElevatedCard(radius: CGFloat = AppVisual.cardRadius) -> some View {
        background(
            AppCardBackground(radius: radius, style: .elevated)
        )
        .compositingGroup()
        .shadow(color: .black.opacity(0.16), radius: 10, x: 0, y: 5)
    }

    /// Inset cell — gradient + border, no shadow (scroll-friendly).
    func appInsetCell(radius: CGFloat = AppVisual.cellRadius) -> some View {
        background(
            AppCardBackground(radius: radius, style: .inset)
        )
    }

    /// Glass panel for tab bar / toolbars.
    /// Transparent navigation shell — lets `AppBackgroundView` show through tab screens.
    func appScreenChrome() -> some View {
        background(Color.clear)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }

    func appScrollChrome() -> some View {
        scrollContentBackground(.hidden)
    }

    func appGlassPanel(radius: CGFloat = 24) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(Color("AppSurface").opacity(0.82))
                .overlay(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(Color("AppTextPrimary").opacity(0.1), lineWidth: 1)
                )
        )
        .compositingGroup()
        .shadow(color: .black.opacity(0.22), radius: 14, x: 0, y: -4)
    }

    /// Primary CTA — static shadow (never animate radius).
    func appGlowButton(radius: CGFloat = AppLayout.cellRadius, destructive: Bool = false) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(
                    destructive
                        ? LinearGradient(colors: [.red.opacity(0.9), .red.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                        : AppVisual.buttonGradient
                )
                .overlay(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(Color("AppTextPrimary").opacity(0.15), lineWidth: 1)
                )
        )
        .compositingGroup()
        .shadow(
            color: (destructive ? Color.red : Color("AppPrimary")).opacity(0.32),
            radius: 8,
            x: 0,
            y: 4
        )
    }

    func appAccentStripe(_ color: Color, width: CGFloat = 4) -> some View {
        overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: width)
                .padding(.vertical, 12)
                .padding(.leading, 2)
        }
    }
}

// MARK: - Decorative background orbs (static, no blur)

struct AppAmbientOrbs: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color("AppPrimary").opacity(0.28))
                .frame(width: 280, height: 280)
                .offset(x: -120, y: -80)
            Circle()
                .fill(Color("AppAccent").opacity(0.22))
                .frame(width: 240, height: 240)
                .offset(x: 140, y: 140)
            Circle()
                .fill(Color("AppSurface").opacity(0.45))
                .frame(width: 200, height: 200)
                .offset(x: 50, y: -170)
        }
        .allowsHitTesting(false)
        .drawingGroup()
    }
}
