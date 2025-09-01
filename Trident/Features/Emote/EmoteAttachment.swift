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
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func attachmentBounds(
    for textContainer: NSTextContainer?,
    proposedLineFragment lineFrag: CGRect,
    glyphPosition position: CGPoint,
    characterIndex charIndex: Int
  ) -> CGRect {
    let height = emote.max { $0.height < $1.height }?.size(multiplier: multiplier).height
    let width = emote.max { $0.width < $1.width }?.size(multiplier: multiplier).width
    guard let height, let width else { return .zero }

    return CGRect(
      x: 0,
      y: (lineFrag.height - height) / 2, // Center the emote vertically within the line fragment
      width: width,
      height: height
    )
  }

  override func viewProvider(
    for parentView: UIView?,
    location: NSTextLocation,
    textContainer: NSTextContainer?
  ) -> NSTextAttachmentViewProvider? {
    EmoteAttachmentViewProvider(
      textAttachment: self,
      parentView: parentView,
      textLayoutManager: textContainer?.textLayoutManager,
      location: location
    )
  }
}
