import AudioToolbox
import UIKit

@MainActor
enum Feedback {
  private static var sound: SystemSoundID = 0
  static func selection(_ settings: StudioSettings) {
    if settings.haptics { UISelectionFeedbackGenerator().selectionChanged() }
  }
  static func correct(_ settings: StudioSettings) {
    if settings.haptics { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    if settings.sound {
      if sound == 0, let url = Bundle.main.url(forResource: "Snip", withExtension: "wav") {
        AudioServicesCreateSystemSoundID(url as CFURL, &sound)
      }
      if sound != 0 { AudioServicesPlaySystemSound(sound) }
    }
  }
  static func incorrect(_ settings: StudioSettings) {
    if settings.haptics { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
  }
}
