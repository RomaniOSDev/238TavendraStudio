import SwiftUI

struct NotificationPermissionView: View {
    var onAccept: () -> Void
    var onDecline: () -> Void

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 20) {
                Spacer(minLength: 0)
                iconSection
                textSection
                Spacer(minLength: 0)
                buttonsSection
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }

    private var iconSection: some View {
        ZStack {
            Circle()
                .fill(Color("AppSurface"))
                .frame(width: 116, height: 116)
                .overlay(
                    Circle()
                        .stroke(Color("AppAccent").opacity(0.4), lineWidth: 1.2)
                )
                .shadow(color: Color("AppPrimary").opacity(0.3), radius: 14)

            Image(systemName: "bell.badge.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color("AppPrimary"), Color("AppAccent")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
    }

    private var textSection: some View {
        VStack(spacing: 12) {
            Text("Enable Notifications")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color("AppTextPrimary"))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text("Stay updated with important news and bonus. You can change this later in Settings.")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(Color("AppTextSecondary"))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
    }

    private var buttonsSection: some View {
        VStack(spacing: 14) {
            Button(action: onAccept) {
                Text("Enable")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color("AppPrimary"), Color("AppAccent")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)

            Button(action: onDecline) {
                Text("Not Now")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color("AppTextSecondary"))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color("AppSurface"))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color("AppAccent").opacity(0.3), lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NotificationPermissionView(onAccept: {}, onDecline: {})
}
