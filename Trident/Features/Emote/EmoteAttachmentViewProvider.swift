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

        view = MainActor.assumeIsolated {
            let attachmentView = EmoteAttachmentView()
            attachmentView.emote = emote
            return attachmentView
        }
    }

    override func attachmentBounds(
        for attributes: [NSAttributedString.Key: Any],
        location: any NSTextLocation,
        textContainer: NSTextContainer?,
        proposedLineFragment: CGRect,
        position: CGPoint
    ) -> CGRect {
        guard let textAttachment = textAttachment as? EmoteAttachment else { return .zero }
        let emoteSize = textAttachment.emote.size(fontHeight: textAttachment.fontSize)

        // center the emote vertically within the line fragment
        return CGRect(
            x: 0, y: (proposedLineFragment.height - emoteSize.height) / 2,
            width: emoteSize.width + 4, height: emoteSize.height
        )
    }
}
