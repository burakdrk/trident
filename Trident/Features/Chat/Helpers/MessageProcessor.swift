import DataModels
import UIKit

nonisolated enum MessageProcessor {
  @concurrent static func makeAttributedString(
    for message: ChatMessage,
    font: UIFont
  ) async -> NSAttributedString {
    let out = NSMutableAttributedString()
    let alpha = message.historical ? 0.5 : 1.0

    let attrs: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: UIColor.label.withAlphaComponent(alpha)
    ]

    // MARK: - Timestamp

    let smallFont = UIFont.systemFont(ofSize: font.pointSize * 0.7)
    out.append(NSAttributedString(
      string: message.timestamp.formattedTime + " ",
      attributes: [
        .font: smallFont,
        .foregroundColor: UIColor.secondaryLabel.withAlphaComponent(alpha),
        .baselineOffset: (font.pointSize - smallFont.pointSize) / 2 - 1
      ]
    ))

    // MARK: - Display name

    out.append(
      NSAttributedString(
        string: message.author.displayName,
        attributes: [
          .font: UIFont.boldSystemFont(ofSize: font.pointSize),
          .foregroundColor: (UIColor(hex: message.author.colorHex) ?? .gray)
            .withAlphaComponent(alpha)
        ]
      )
    )
    out.append(NSAttributedString(string: ": ", attributes: attrs))

    // MARK: - Message body

    for inline in message.inlines {
      switch inline {
      case let .emote(emote):
        let att = EmoteAttachment(emote, historical: message.historical)
        out.append(NSAttributedString(attachment: att))
      case let .text(text):
        out.append(NSAttributedString(string: text, attributes: attrs))
      }
    }

    // Force fixed line height for all wrapped lines in this paragraph
    let pst = NSMutableParagraphStyle()
    pst.lineSpacing = 4
    pst.baseWritingDirection = .leftToRight

    let full = NSRange(location: 0, length: out.length)

    out.enumerateAttribute(.font, in: full, options: []) { value, range, _ in
      guard value is UIFont else { return }
      out.addAttribute(.paragraphStyle, value: pst, range: range)
    }

    return out
  }
}
