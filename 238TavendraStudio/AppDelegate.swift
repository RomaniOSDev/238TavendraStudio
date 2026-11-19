import UIKit
import SwiftUI
import AppTrackingTransparency
import AdjustSdk
import OneSignalFramework

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    static var orientationLock: UIInterfaceOrientationMask = .all
    static let crimsonLatticeBloomfield = "crimsonLatticeBloomfield"
    private var tarnishedEmberChoirs = false
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        AppDelegate.orientationLock
    }
    
    func application(_ application: UIApplication,didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        UserDefaults.standard.set(
            ATTrackingManager.trackingAuthorizationStatus != .notDetermined,
            forKey: Self.crimsonLatticeBloomfield)
        
        if let config = ADJConfig(appToken: "84nu0bfbwrk0", environment: ADJEnvironmentProduction) {
            config.logLevel = .verbose
            config.attConsentWaitingInterval = 20
            Adjust.initSdk(config)
        }
        
        OneSignal.initialize("01ef71b7-49d1-4490-a2f0-5b6ab0f5f917", withLaunchOptions: launchOptions)
        return true
    }
    
    func saggingFogVigil() {
        guard !tarnishedEmberChoirs, ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        tarnishedEmberChoirs = true
        
        Task {
            defer { tarnishedEmberChoirs = false }
            try? await Task.sleep(for: .seconds(1))
            guard UIApplication.shared.applicationState == .active else { return }
            _ = await Adjust.requestAppTrackingAuthorization()
            let shimmeringAnvilTides = ATTrackingManager.trackingAuthorizationStatus != .notDetermined
            UserDefaults.standard.set(shimmeringAnvilTides, forKey: AppDelegate.crimsonLatticeBloomfield)
        }
    }
}
