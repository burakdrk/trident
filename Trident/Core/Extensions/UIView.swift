//
//  UIView.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-06.
//

import UIKit

extension UIView {
  /// Adds a subview and sets its constraints to fill the parent view.
  /// - Parameter subview: The view to add as a subview.
  func addAndFillSubview(_ subview: UIView) {
    addSubview(subview)
    subview.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      subview.topAnchor.constraint(equalTo: topAnchor),
      subview.bottomAnchor.constraint(equalTo: bottomAnchor),
      subview.leadingAnchor.constraint(equalTo: leadingAnchor),
      subview.trailingAnchor.constraint(equalTo: trailingAnchor)
    ])
  }
}
