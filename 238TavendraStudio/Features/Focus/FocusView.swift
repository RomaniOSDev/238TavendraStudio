import Combine
import SwiftUI

@MainActor
final class FocusViewModel: ObservableObject {
    @Published var showSettings = false
    @Published var showInAppBanner = false
    @Published var bannerMessage = ""
    @Published var buttonEnlarged = false

    func triggerSessionCompleteAnimation() {
        buttonEnlarged = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            self.buttonEnlarged = false
        }
    }

    func showBanner(_ message: String) {
        bannerMessage = message
        showInAppBanner = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showInAppBanner = false
        }
    }
}

struct FocusView: View {
    @EnvironmentObject private var store: AppDataStore
    @StateObject private var viewModel = FocusViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 24) {
                    contextPicker
                    suggestedTaskCard
                    timerSection
                    presetPicker
                    sessionsTodayCard

                    if store.focusSessions.isEmpty {
                        emptyState
                    } else {
                        sessionHistory
                    }

                    Spacer(minLength: 100)
                }
                .padding(16)
            }
            .appScrollChrome()

            if viewModel.showInAppBanner {
                InAppBannerView(message: viewModel.bannerMessage)
                    .padding(.top, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(10)
            }

            VStack {
                Spacer()
                startButton
            }
        }
        .navigationTitle("Focus")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    FeedbackManager.lightTap()
                    viewModel.showSettings = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                        .foregroundStyle(Color("AppPrimary"))
                }
                .frame(minWidth: 44, minHeight: 44)
            }
        }
        .sheet(isPresented: $viewModel.showSettings) {
            FocusSettingsSheet()
                .environmentObject(store)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                store.checkTimerCompletion()
            }
        }
        .onChange(of: store.sessionCompletionNotice) { notice in
            guard let notice else { return }
            viewModel.showBanner(notice)
            viewModel.triggerSessionCompleteAnimation()
            store.sessionCompletionNotice = nil
        }
    }

    private var contextPicker: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                AppSectionHeader(title: "Work Context", subtitle: "Pick your focus mode", icon: "brain.head.profile")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(WorkContext.allCases) { context in
                            ContextCardCell(
                                context: context,
                                durationMin: store.durationForContext(context) / 60,
                                sessionCount: store.focusSessions(for: context).count,
                                isSelected: store.activeFocusContext == context
                            ) {
                                FeedbackManager.lightTap()
                                store.activeFocusContext = context
                                if !store.timerIsRunning {
                                    store.workDurationSec = store.durationForContext(context)
                                    store.timerRemainingSec = store.workDurationSec
                                }
                            }
                        }
                    }
                }
                ContextConflictBanner(conflicts: store.contextConflicts(for: store.activeFocusContext))
            }
        }
    }

    private var suggestedTaskCard: some View {
        Group {
            if let task = store.suggestedNextTask() {
                ActionBannerCell(
                    icon: task.workContext.iconName,
                    title: "Suggested: \(task.title)",
                    subtitle: "\(task.workContext.rawValue) · \(task.energyLevel.rawValue) energy",
                    accent: Color("AppAccent")
                ) {
                    store.startFocusWithContext(task.workContext, task: task)
                }
            }
        }
    }

    private var timerSection: some View {
        AppCard(accent: Color("AppPrimary")) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                FocusTimerDisplay(
                    label: store.currentTimerType == .work ? store.activeFocusContext.rawValue : "Break",
                    timeText: formattedTime(store.displayRemainingSeconds(at: context.date)),
                    isRunning: store.timerIsRunning,
                    progress: store.timerProgress(at: context.date)
                )
            }
        }
    }

    private var sessionsTodayCard: some View {
        AppCard {
            HStack(spacing: 14) {
                AppMetricTile(icon: "clock.fill", value: "\(store.focusSessionsToday)", label: "Sessions Today")
                AppMetricTile(icon: "hourglass", value: "\(store.totalMinutesUsed)m", label: "Total Focus")
            }
        }
    }

    private var emptyState: some View {
        AppEmptyState(
            icon: "clock.circle.fill",
            title: "Ready to Focus",
            message: "Ready to focus? Start your first session"
        )
    }

    private var sessionHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            AppSectionHeader(title: "Session History", icon: "list.bullet.rectangle")
            ForEach(store.focusSessions.prefix(20)) { session in
                FocusSessionCell(session: session, projectName: store.projectName(for: session.projectId))
            }
        }
    }

    private var startButton: some View {
        AppPrimaryButton(
            title: store.timerIsRunning ? "Stop Session" : "Start Focus",
            icon: store.timerIsRunning ? "stop.fill" : "play.fill"
        ) {
            if store.timerIsRunning {
                store.stopFocusTimer()
            } else {
                store.startFocusWithContext(store.activeFocusContext, task: store.suggestedNextTask())
            }
        }
        .padding(.horizontal, AppLayout.padding)
        .padding(.bottom, 16)
        .scaleEffect(viewModel.buttonEnlarged ? 1.05 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: viewModel.buttonEnlarged)
    }

    private var presetPicker: some View {
        Picker("Duration", selection: Binding(
            get: { store.focusPreset },
            set: { store.applyFocusPreset($0) }
        )) {
            ForEach(FocusPreset.allCases) { preset in
                Text(preset.rawValue).tag(preset)
            }
        }
        .pickerStyle(.segmented)
        .disabled(store.timerIsRunning)
    }

    private func formattedTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}

struct FocusSettingsSheet: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss

    @State private var breakMinutes = 5

    private func contextMinutes(_ context: WorkContext) -> Int {
        store.durationForContext(context) / 60
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                Form {
                    Section("Context Durations") {
                        ForEach(WorkContext.allCases) { context in
                            Stepper(
                                "\(context.rawValue): \(contextMinutes(context)) min",
                                value: Binding(
                                    get: { contextMinutes(context) },
                                    set: { store.setDurationForContext(context, seconds: $0 * 60) }
                                ),
                                in: 5...90,
                                step: 5
                            )
                        }
                    }
                    Section("Pomodoro Preset") {
                        Picker("Preset", selection: Binding(
                            get: { store.focusPreset },
                            set: { store.applyFocusPreset($0) }
                        )) {
                            ForEach(FocusPreset.allCases) { preset in
                                Text(preset.rawValue).tag(preset)
                            }
                        }
                    }
                    Section("Break Duration") {
                        Stepper("\(breakMinutes) min", value: $breakMinutes, in: 1...30, step: 1)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Timer Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        FeedbackManager.lightTap()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.breakDurationSec = breakMinutes * 60
                        if !store.timerIsRunning {
                            store.timerRemainingSec = store.currentTimerType == .work
                                ? store.durationForContext(store.activeFocusContext)
                                : store.breakDurationSec
                        }
                        FeedbackManager.success()
                        dismiss()
                    }
                    .foregroundStyle(Color("AppPrimary"))
                }
            }
            .onAppear {
                breakMinutes = store.breakDurationSec / 60
            }
        }
        .presentationDetents([.large])
    }
}
