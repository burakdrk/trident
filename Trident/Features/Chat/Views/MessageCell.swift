//
//  MessageCell.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-07.
//

import SwiftUI
import UIKit

final class MessageCell: UITableViewCell {
  static let reuseID = "MessageCellId"

  let textView: UITextView = LinkOnlyTextView()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)

    // Configure the cell
    selectionStyle = .none
    transform = CGAffineTransform(scaleX: 1, y: -1)

    setupTextView() // Setup the text view with necessary properties
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Configuration

  private func setupTextView() {
    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.isEditable = false
    textView.isSelectable = true
    textView.dataDetectorTypes = [.link]
    textView.isScrollEnabled = false
    textView.backgroundColor = .clear
    textView.textContainerInset = .zero
    textView.textContainer.lineFragmentPadding = .zero

    contentView.addSubview(textView)

    NSLayoutConstraint.activate([
      textView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
      textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
      textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
      textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
    ])
  }
}

// MARK: - Message Rendering

extension MessageCell {
  func makeMessage(message: ChatMessage, font: UIFont) {
    let out = NSMutableAttributedString()

    let attrs: [NSAttributedString.Key: Any] = [
      .font: font,
      .foregroundColor: UIColor.label
    ]

    // Timestamp
    let smallFont = UIFont.systemFont(ofSize: font.pointSize * 0.7)
    out.append(NSAttributedString(
      string: message.timestamp.formattedTime + " ",
      attributes: [
        .font: smallFont,
        .foregroundColor: UIColor.secondaryLabel,
        .baselineOffset: (font.pointSize - smallFont.pointSize) / 2 - 1
      ]
    ))

    // Display name
    out.append(
      NSAttributedString(
        string: message.author.displayName,
        attributes: [
          .font: UIFont.boldSystemFont(ofSize: font.pointSize),
          .foregroundColor: UIColor(hex: message.author.colorHex) ?? .gray
        ]
      )
    )
    out.append(NSAttributedString(string: ": ", attributes: attrs))

    // Message body
    for inline in message.inlines {
      switch inline {
      case let .emote(emote):
        let att = EmoteAttachment(emote)
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

    textView.attributedText = out
  }
}

// MARK: - Preview

struct CustomCellPreview: PreviewProvider {
  static var previews: some View {
    CellPreviewContainer()
      .frame(width: .infinity, height: 100)
      .transformEffect(CGAffineTransform(scaleX: 1, y: -1)) // Flip the preview back
  }

  struct CellPreviewContainer: UIViewRepresentable {
    func makeUIView(context _: Context) -> UITableViewCell {
      let cell = MessageCell(style: .default, reuseIdentifier: MessageCell.reuseID)
      cell.makeMessage(message: .mock, font: .systemFont(ofSize: 20))
      return cell
    }

    func updateUIView(_: UITableViewCell, context _: Context) { /* noop */ }

    typealias UIViewType = UITableViewCell
  }
}
