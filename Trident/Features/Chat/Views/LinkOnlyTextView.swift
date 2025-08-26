//
//  LinkOnlyTextView.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-09.
//

import UIKit

final class LinkOnlyTextView: UITextView {
    override var canBecomeFirstResponder: Bool { false } // no edit menu
    override var selectedTextRange: UITextRange? { // block selection
        get { nil }
        set {}
    }

    override func selectionRects(for range: UITextRange) -> [UITextSelectionRect] { [] } // no highlight
}
