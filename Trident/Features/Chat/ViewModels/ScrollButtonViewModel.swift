//
//  ScrollButtonViewModel.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-07.
//

import SwiftUI

@Observable final class ScrollButtonViewModel {
    private var isAnimating = false
    private var storedMessageCount = 0

    var isShown = false
    var newMessageCount: Int {
        get { storedMessageCount }
        set {
            if isAnimating {
                return
            }

            storedMessageCount = newValue
        }
    }

    @MainActor
    func setShown(_ shown: Bool, animated: Bool = true) {
        if animated {
            isAnimating = true
            withAnimation(.easeOut(duration: 0.25)) {
                isShown = shown
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                self.isAnimating = false
            }
        } else {
            isShown = shown
            isAnimating = false
        }
    }
}
