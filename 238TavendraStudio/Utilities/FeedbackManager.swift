import AudioToolbox
import UIKit

enum FeedbackManager {
  static func lightTap() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    AudioServicesPlaySystemSound(1003)
  }

  static func mediumAction() {
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
  }

  static func success() {
    UINotificationFeedbackGenerator().notificationOccurred(.success)
    AudioServicesPlaySystemSound(1057)
  }

  static func warning() {
    UINotificationFeedbackGenerator().notificationOccurred(.warning)
  }

  static func focusComplete() {
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    AudioServicesPlaySystemSound(1104)
  }

  static func taskComplete() {
    UINotificationFeedbackGenerator().notificationOccurred(.success)
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
  }

  static func achievementUnlocked() {
    UINotificationFeedbackGenerator().notificationOccurred(.success)
    AudioServicesPlaySystemSound(1057)
  }
}
