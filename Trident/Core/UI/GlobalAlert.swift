import UIKit

@MainActor
enum GlobalAlert {
  static func show(
    title: String,
    message: String? = nil,
    actions: [UIAlertAction] = [UIAlertAction(title: "OK", style: .default)]
  ) {
    guard let scene = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .first(where: { $0.activationState == .foregroundActive }),
      let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
    else {
      return
    }

    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    actions.forEach { alert.addAction($0) }

    // Find topmost VC
    var top = root
    while let presented = top.presentedViewController {
      top = presented
    }
    top.present(alert, animated: true)
  }
}
