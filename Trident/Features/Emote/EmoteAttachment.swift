//
//  EmoteAttachment.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-07.
//

import SDWebImage
import UIKit
import UniformTypeIdentifiers

final class EmoteAttachment: NSTextAttachment {
  let emote: [Emote]
  let multiplier: CGFloat
  let historical: Bool

  init(_ emote: [Emote], historical: Bool = false, multiplier: CGFloat = 1.0) {
    self.emote = emote
    self.historical = historical
    self.multiplier = multiplier

    super.init(data: nil, ofType: UTType.image.identifier)

    allowsTextAttachmentView = true
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewProvider(
    for parentView: UIView?,
    location: NSTextLocation,
    textContainer: NSTextContainer?
  ) -> NSTextAttachmentViewProvider? {
    let viewProvider = EmoteAttachmentViewProvider(
      textAttachment: self,
      parentView: parentView,
      textLayoutManager: textContainer?.textLayoutManager,
      location: location
    )

    viewProvider.tracksTextAttachmentViewBounds = true
    return viewProvider
  }
}
