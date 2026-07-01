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

#Preview {
    ContentView()
}
