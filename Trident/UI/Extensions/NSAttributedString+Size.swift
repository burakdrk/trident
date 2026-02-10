import UIKit

public extension NSAttributedString {
  nonisolated func sizeFittingWidth(_ w: CGFloat) -> CGSize {
    let textStorage = NSTextStorage(attributedString: self)
    let size = CGSize(width: w, height: CGFloat.greatestFiniteMagnitude)
    let boundingRect = CGRect(origin: .zero, size: size)

    let textContainer = NSTextContainer(size: size)
    textContainer.lineFragmentPadding = 0

    let layoutManager = NSLayoutManager()
    layoutManager.addTextContainer(textContainer)

    textStorage.addLayoutManager(layoutManager)

    layoutManager.glyphRange(forBoundingRect: boundingRect, in: textContainer)

    let rect = layoutManager.usedRect(for: textContainer)

    return rect.integral.size
  }
}
