import SDWebImage
import UIKit

final nonisolated class EmoteAttachmentViewProvider: NSTextAttachmentViewProvider {
  override func loadView() {
    guard let textAttachment = textAttachment as? EmoteAttachment else { return }
    let emote = textAttachment.emote
    let historical = textAttachment.historical

    view = MainActor.assumeIsolated {
      // MARK: - Single Emote Renderer

      if emote.count == 1 {
        let imageView = SDAnimatedImageView()
        imageView.animationGroup = emote[0].id
        imageView.sd_setImage(with: emote[0].url, placeholderImage: nil)
        if historical { imageView.alpha = 0.5 }
        return imageView
      }

      // MARK: - Overlay Renderer

      let container = UIView()
      container.isOpaque = false

      // Base
      let baseView = SDAnimatedImageView()
      container.addAndFillSubview(baseView)

      // Overlays
      var overlayViews: [SDAnimatedImageView] = []
      for _ in emote {
        let v = SDAnimatedImageView()
        container.addAndFillSubview(v)
        overlayViews.append(v)
      }

      // Load images
      baseView.animationGroup = emote[0].id
      baseView.sd_setImage(with: emote[0].url, placeholderImage: nil)
      for (i, e) in emote.enumerated() {
        if i == 0 { continue }

        overlayViews[i].animationGroup = e.id
        overlayViews[i].sd_setImage(with: e.url, placeholderImage: nil)
      }

      if historical { container.alpha = 0.5 }
      return container
    }
  }
}
