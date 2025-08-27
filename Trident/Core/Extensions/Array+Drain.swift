import Collections

extension Array {
  mutating func drain() -> [Element] {
    let batch = self
    removeAll()
    return batch
  }
}

extension Deque {
  mutating func drain() -> Deque<Element> {
    let batch = self
    removeAll()
    return batch
  }
}
