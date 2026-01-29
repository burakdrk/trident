import SwiftUI
import UIKit

private enum HapticFeedbackGenerator {
  static let impactLightFeedbackGenerator = UIImpactFeedbackGenerator(
    style: .light
  )
  static let impactMediumFeedbackGenerator = UIImpactFeedbackGenerator()
  static let impactHeavyFeedbackGenerator = UIImpactFeedbackGenerator(
    style: .heavy
  )
  static let selectionFeedbackGenerator = UISelectionFeedbackGenerator()
  static let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
}

enum HapticFeedbackStyle {
  case impactLight
  case impactMedium
  case impactHeavy
  case selection
  case notifySuccess
  case notifyWarning
  case notifyError
}

protocol HapticFeedbackProvider {
  func hapticFeedback(_ style: HapticFeedbackStyle)
}

extension HapticFeedbackProvider {
  func hapticFeedback(_ style: HapticFeedbackStyle) {
    Self.hapticFeedback(style)
  }

  static func hapticFeedback(_ style: HapticFeedbackStyle) {
    switch style {
    case .impactLight:
      HapticFeedbackGenerator.impactLightFeedbackGenerator.impactOccurred()
    case .impactMedium:
      HapticFeedbackGenerator.impactMediumFeedbackGenerator.impactOccurred()
    case .impactHeavy:
      HapticFeedbackGenerator.impactHeavyFeedbackGenerator.impactOccurred()
    case .selection:
      HapticFeedbackGenerator.selectionFeedbackGenerator.selectionChanged()
    case .notifySuccess:
      HapticFeedbackGenerator.notificationFeedbackGenerator
        .notificationOccurred(.success)
    case .notifyWarning:
      HapticFeedbackGenerator.notificationFeedbackGenerator
        .notificationOccurred(.warning)
    case .notifyError:
      HapticFeedbackGenerator.notificationFeedbackGenerator
        .notificationOccurred(.error)
    }
  }
}

struct HapticFeedbackViewProxy: HapticFeedbackProvider {
  func generate(_ style: HapticFeedbackStyle) {
    Self.hapticFeedback(style)
  }
}

extension View {
  var haptics: HapticFeedbackViewProxy {
    HapticFeedbackViewProxy()
  }
}

extension UIViewController {
  var haptics: HapticFeedbackViewProxy {
    HapticFeedbackViewProxy()
  }
}
