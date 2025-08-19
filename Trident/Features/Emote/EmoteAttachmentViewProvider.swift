//
//  EmoteAttachmentViewProvider.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-08.
//

import UIKit

final class EmoteAttachmentViewProvider: NSTextAttachmentViewProvider {
  override func loadView() {
    guard let textAttachment = textAttachment as? EmoteAttachment else { return }
    let emote = textAttachment.emote
    let historical = textAttachment.historical

    view = MainActor.assumeIsolated {
      // MARK: - Single Emote Renderer

      if emote.count == 1 {
        let attachmentView = EmoteAttachmentView()
        attachmentView.emote = emote[0]
        if historical { attachmentView.alpha = 0.5 }
        return attachmentView
      }

      // MARK: - Overlay Renderer

      let container = UIView()
      container.isOpaque = false

      // Base
      let baseView = EmoteAttachmentView()
      container.addAndFillSubview(baseView)

      // Overlays
      var overlayViews: [EmoteAttachmentView] = []
      for _ in emote {
        let v = EmoteAttachmentView()
        container.addAndFillSubview(v)
        overlayViews.append(v)
      }

      // Load images
      baseView.emote = emote[0]
      for (i, e) in emote.enumerated() {
        if i == 0 { continue }
        overlayViews[i].emote = e
      }

      if historical { container.alpha = 0.5 }
      return container
    }
  }

  override func attachmentBounds(
    for _: [NSAttributedString.Key: Any],
    location _: any NSTextLocation,
    textContainer _: NSTextContainer?,
    proposedLineFragment: CGRect,
    position _: CGPoint
  ) -> CGRect {
    guard let textAttachment = textAttachment as? EmoteAttachment else { return .zero }
    let emoteSize = textAttachment.emote[0].size(multiplier: textAttachment.multiplier)

    // center the emote vertically within the line fragment
    return CGRect(
      x: 0, y: (proposedLineFragment.height - emoteSize.height) / 2,
      width: emoteSize.width, height: emoteSize.height
    )
  }
}
