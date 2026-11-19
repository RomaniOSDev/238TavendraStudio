//
//  ContentView.swift
//  238TavendraStudio
//
//  Created by Roman on 7/1/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = AppDataStore.shared

    var body: some View {
        ZStaсk {
            Group {
                if store.hasSeenOnboarding {
                    MainTabView()
                } else {
                    OnboardingView()
                }
            }
            .environmentObject(store)
            .preferredColorScheme(.dark)
            .onAppear {
                store.evaluateAchievements()
            }
        }
    }
}

struct SplashScreen: View {
    @State private var appeared = false

    var body: some View {
        ZStack {
            AppBackgroundView()

            VStack(spacing: 22) {
                mark

                VStack(spacing: 6) {
                    Text("Tavendra Studio")
                        .font(.title.bold())
                        .foregroundStyle(Color("AppTextPrimary"))
                    Text("Energy × Blocks × Context")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color("AppAccent"))
                }

                ProgressView()
                    .controlSize(.large)
                    .tint(Color("AppPrimary"))
                    .padding(.top, 12)
            }
            .scaleEffect(appeared ? 1 : 0.92)
            .opacity(appeared ? 1 : 0)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.78)) {
                appeared = true
            }
        }
    }

    private var mark: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color("AppPrimary").opacity(0.28),
                            Color("AppPrimary").opacity(0.06)
                        ],
                        center: .center,
                        startRadius: 8,
                        endRadius: 72
                    )
                )
                .frame(width: 132, height: 132)

            Circle()
                .stroke(AppVisual.ringGradient, lineWidth: 3)
                .frame(width: 112, height: 112)

            AppIconBadge(icon: "bolt.horizontal.fill", size: 72, tint: Color("AppPrimary"))
        }
        .accessibilityHidden(true)
    }
}

#Preview("Splash") {
    SplashScreen()
}


