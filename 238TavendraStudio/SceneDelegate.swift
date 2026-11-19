import UIKit
import SwiftUI
import AppTrackingTransparency
import AdjustSdk
import OneSignalFramework

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.backgroundColor = UIColor(named: "AppBackground") ?? .black
        window.rootViewController = UIHostingController(rootView: ContentView())
        window.makeKeyAndVisible()
        self.window = window
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        (UIApplication.shared.delegate as? AppDelegate)?.saggingFogVigil()
    }
}
