//
//  Array+drain.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-04.
//

import Collections

extension Array {
  mutating func drain() -> [Element] {
    let batch = self
    self.removeAll()
    return batch
  }
}

extension Deque {
  mutating func drain() -> Deque<Element> {
    let batch = self
    self.removeAll()
    return batch
  }
}
