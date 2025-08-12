//
//  MessageCell.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-07.
//

import SDWebImage
import UIKit

final class MessageCell: UITableViewCell {
  static let reuseID = "MessageCellId"

  let textView: UITextView = {
    let newTextView = LinkOnlyTextView()
    newTextView.translatesAutoresizingMaskIntoConstraints = false
    newTextView.isEditable = false
    newTextView.isSelectable = true
    newTextView.dataDetectorTypes = [.link]
    newTextView.isScrollEnabled = false
    newTextView.backgroundColor = .clear
    newTextView.textContainerInset = .zero
    newTextView.textContainer.lineFragmentPadding = 0
    // newTextView.textContainerInset = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
    return newTextView
  }()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)

    selectionStyle = .none
    transform = CGAffineTransform(scaleX: 1, y: -1)
    contentView.addSubview(textView)

    NSLayoutConstraint.activate([
      textView.topAnchor.constraint(
        equalTo: contentView.topAnchor,
        constant: 2
      ),
      textView.leadingAnchor.constraint(
        equalTo: contentView.leadingAnchor,
        constant: 0
      ),
      textView.trailingAnchor.constraint(
        equalTo: contentView.trailingAnchor,
        constant: 0
      ),
      textView.bottomAnchor.constraint(
        equalTo: contentView.bottomAnchor,
        constant: -2
      )
    ])
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func makeMessage(message: RenderableMessage, font: UIFont) {
    let out = NSMutableAttributedString()
    let attrs: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: UIColor.label,
      .backgroundColor: UIColor.red,
      .baselineOffset: 10
    ]

    let padding: CGFloat = font.lineHeight / 2

    let topSpacer = NSTextAttachment()
    topSpacer.bounds = CGRect(x: 0, y: -padding, width: 0, height: padding)

    let bottomSpacer = NSTextAttachment()
    bottomSpacer.bounds = CGRect(
      x: 0,
      y: padding,
      width: 0,
      height: padding
    )

    for chunk in message.chunks {
      switch chunk.type {
      case .emote:
        guard let emote = chunk.emote else { continue }
        let att = EmoteAttachment(emote: emote, fontSize: font.lineHeight)
        out.append(NSAttributedString(attachment: att))
      case .body:
        // out.append(NSAttributedString(attachment: topSpacer))
        out.append(
          NSAttributedString(string: chunk.text + " ", attributes: attrs)
        )
      // out.append(NSAttributedString(attachment: bottomSpacer))
      case .displayName:
        out.append(
          NSAttributedString(
            string: chunk.text,
            attributes: [
              .font: UIFont.boldSystemFont(ofSize: font.pointSize),
              .foregroundColor: UIColor(hex: message.details.color) ?? .gray
            ]
          )
        )
        out.append(NSAttributedString(string: ": ", attributes: attrs))
      case .timestamp:
        break
      }
    }

    textView.attributedText = out
  }
}
