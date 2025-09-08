import SwiftUI

struct BackgroundHelper: UIViewControllerRepresentable {
  @Environment(\.theme) private var theme

  final class HelperVC: UIViewController {
    var color: UIColor

    init(color: UIColor) {
      self.color = color
      super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override func didMove(toParent parent: UIViewController?) {
      super.didMove(toParent: parent)
      var currParent = parent
      while true {
        guard let parent = currParent else {
          break
        }
        if parent.tabBarController?.viewControllers?.contains(parent) == true {
          currParent?.view.backgroundColor = color
          parent.tabBarController?.view.backgroundColor = color
          break
        }
        currParent = currParent?.parent
      }
    }
  }

  func makeUIViewController(context: Context) -> HelperVC {
    HelperVC(color: UIColor(theme.bg))
  }

  func updateUIViewController(_ uiViewController: HelperVC, context: Context) {
    uiViewController.color = UIColor(theme.bg)
  }
}
