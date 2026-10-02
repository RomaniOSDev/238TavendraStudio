import SwiftUI

struct NoInternetView: View {
    var onRetry: () -> Void

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 18) {
                Spacer(minLength: 0)

                ZStack {
                    Circle()
                        .fill(Color("AppSurface"))
                        .frame(width: 112, height: 112)
                        .overlay(
                            Circle()
                                .stroke(Color("AppAccent").opacity(0.4), lineWidth: 1.2)
                        )
                        .shadow(color: Color("AppPrimary").opacity(0.3), radius: 14)

                    Image(systemName: "wifi.slash")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color("AppPrimary"), Color("AppAccent")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }

                Text("No Internet Connection")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("AppTextPrimary"))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Please check your connection and try again.")
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundStyle(Color("AppTextSecondary"))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 12)

                Spacer(minLength: 0)

                Button(action: onRetry) {
                    Text("Retry")
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
                .padding(.horizontal, 24)
                .padding(.bottom, 48)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .preferredColorScheme(.dark)
    }
}

#Preview {
    NoInternetView(onRetry: {})
}
