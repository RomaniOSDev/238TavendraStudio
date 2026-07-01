import SwiftUI

enum WellnessSegment: String, CaseIterable, Identifiable {
    case focus = "Focus"
    case habits = "Routines"

    var id: String { rawValue }
}

struct WellnessHubView: View {
    @State private var selectedSegment: WellnessSegment = .focus

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                VStack(spacing: 0) {
                    Picker("Section", selection: $selectedSegment) {
                        ForEach(WellnessSegment.allCases) { segment in
                            Text(segment.rawValue).tag(segment)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .onChange(of: selectedSegment) { _ in
                        FeedbackManager.lightTap()
                    }

                    Group {
                        switch selectedSegment {
                        case .focus:
                            FocusView()
                        case .habits:
                            HabitsView()
                        }
                    }
                }
            }
        }
        .appScreenChrome()
    }
}
