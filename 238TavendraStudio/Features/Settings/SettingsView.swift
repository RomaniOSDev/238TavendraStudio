import StoreKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppDataStore
    @State private var showResetAlert = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                ScrollView {
                    VStack(spacing: 18) {
                        statsCard
                        settingsCard
                        Text("Version \(appVersion)")
                            .font(.caption)
                            .foregroundStyle(Color("AppTextSecondary"))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                    }
                    .padding(AppLayout.padding)
                }
                .appScrollChrome()
            }
            .navigationTitle("Settings")
            .alert("Reset All Data?", isPresented: $showResetAlert) {
                Button("Cancel", role: .cancel) { FeedbackManager.lightTap() }
                Button("Reset", role: .destructive) {
                    store.resetAllData()
                    NotificationCenter.default.post(name: .dataReset, object: nil)
                    FeedbackManager.warning()
                }
            } message: {
                Text("This will permanently delete all tasks, habits, focus sessions, and progress. This action cannot be undone.")
            }
        }
        .appScreenChrome()
    }

    private var statsCard: some View {
        AppCard(accent: Color("AppAccent")) {
            VStack(alignment: .leading, spacing: 14) {
                AppSectionHeader(title: "Your Progress", icon: "chart.line.uptrend.xyaxis")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    AppMetricTile(icon: "tray.full.fill", value: "\(store.tasks.count + store.habits.count)", label: "Total Entries")
                    AppMetricTile(icon: "hourglass", value: "\(store.totalMinutesUsed)m", label: "Minutes Used")
                    AppMetricTile(icon: "timer", value: "\(store.totalSessionsCompleted)", label: "Sessions")
                    AppMetricTile(icon: "flame.fill", value: "\(store.streakDays)d", label: "Streak")
                }
            }
        }
    }

    private var settingsCard: some View {
        AppCard {
            VStack(spacing: 4) {
                SettingsRowCell(title: "Rate Us", icon: "star.fill") {
                    FeedbackManager.lightTap()
                    rateApp()
                }
                divider
                SettingsRowCell(title: "Privacy Policy", icon: "hand.raised.fill") {
                    FeedbackManager.lightTap()
                    openPolicy()
                }
                divider
                SettingsRowCell(title: "Terms of Service", icon: "doc.text.fill") {
                    FeedbackManager.lightTap()
                    openTerms()
                }
                divider
                SettingsRowCell(title: "Reset All Data", icon: "trash.fill", isDestructive: true) {
                    FeedbackManager.lightTap()
                    showResetAlert = true
                }
            }
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Color("AppTextSecondary").opacity(0.15))
            .frame(height: 1)
            .padding(.leading, 52)
    }

    private func openPolicy() {
        if let url = AppLink.privacyPolicy.url {
            UIApplication.shared.open(url)
        }
    }

    private func openTerms() {
        if let url = AppLink.termsOfService.url {
            UIApplication.shared.open(url)
        }
    }

    private func rateApp() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
}
