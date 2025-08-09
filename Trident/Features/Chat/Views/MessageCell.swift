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
        let tv = LinkOnlyTextView()
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.isEditable = false
        tv.isSelectable = true
        tv.dataDetectorTypes = [.link]
        tv.isScrollEnabled = false
        tv.backgroundColor = .clear
        tv.textContainerInset = .zero
        tv.textContainer.lineFragmentPadding = 0
        return tv
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        transform = CGAffineTransform(scaleX: 1, y: -1)
        contentView.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
            textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
            textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func makeMessage(message: RenderableMessage, font: UIFont) {
        let out = NSMutableAttributedString()
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: UIColor.label
        ]

        for chunk in message.chunks {
            switch chunk.type {
            case .emote:
                guard let emote = chunk.emote else { continue }
                let att = EmoteAttachment(emote: emote, fontSize: font.lineHeight)
                out.append(NSAttributedString(attachment: att))
            case .body:
                out.append(NSAttributedString(string: chunk.text + " ", attributes: attrs))
            case .displayName:
                out.append(NSAttributedString(string: chunk.text, attributes: [
                    .font: UIFont.boldSystemFont(ofSize: font.pointSize),
                    .foregroundColor: UIColor(hex: message.details.color) ?? .gray
                ]))
                out.append(NSAttributedString(string: ": ", attributes: attrs))
            case .timestamp:
                break
            }
        }

        textView.attributedText = out
    }
}
