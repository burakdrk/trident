//
//  WeakBox.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-16.
//

import Foundation

struct WeakBox<T: AnyObject> {
  weak var value: T?

  init(value: T) {
    self.value = value
  }
}
