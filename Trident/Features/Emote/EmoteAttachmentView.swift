//
//  EmoteAttachmentView.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-08.
//

import SDWebImage
import UIKit

final class EmoteAttachmentView: UIImageView {
  var emote: Emote? {
    didSet {
      guard emote != oldValue else { return }
      if let oldValue {
        EmotePlayer.unregisterView(self, for: oldValue)
      }
      image = nil
      updatePlayerIfNeeded()
      guard let emote else { return }
      SDWebImageManager.shared.loadImage(
        with: emote.url,
        // options: [.],
        context: [.animatedImageClass: SDAnimatedImage.self],
        progress: nil,
        completed: { [weak self] image, _, _, _, _, _ in
          guard let self, emote == self.emote else {
            return // Emote has changed
          }
          if let image = image as? SDAnimatedImage {
            if !image.sd_isAnimated {
              self.image = image
              return
            }

            EmotePlayer.setAnimatedImage(image, for: emote)
          } else {
            self.image = image
          }
        }
      )
    }
  }

  override func didMoveToWindow() {
    super.didMoveToWindow()
    updatePlayerIfNeeded()
  }

  override func didMoveToSuperview() {
    super.didMoveToSuperview()
    updatePlayerIfNeeded()
  }

  deinit {
    guard let emote else { return }
    let identifier = EmotePlayer.viewIdentifier(self)
    Task { @MainActor in
      EmotePlayer.unregisterView(identifier: identifier, for: emote)
    }
  }

  init() {
    super.init(frame: .zero)
    contentMode = .scaleAspectFit
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func updatePlayerIfNeeded() {
    guard let emote else { return }
    guard window != nil, superview != nil else {
      EmotePlayer.unregisterView(self, for: emote)
      return
    }
    EmotePlayer.registerView(self, for: emote)
  }

  override func display(_ layer: CALayer) {
    guard let emote, let player = EmotePlayer.player(for: emote, view: self),
          let image = player.image
    else {
      super.display(layer)
      return
    }
    layer.contentsScale = image.scale
    layer.contents = image.cgImage
  }
}
