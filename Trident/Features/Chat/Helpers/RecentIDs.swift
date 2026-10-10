import Collections

/// Remembers the last `capacity` message ids, so a message that reaches us twice (live and from
/// the recents service) is only shown once, without the set growing forever.
nonisolated struct RecentIDs {
  private let capacity: Int
  private var order: Deque<String> = []
  private var ids: Set<String> = []

  init(capacity: Int) {
    self.capacity = capacity
  }

  /// Returns false if the id was already remembered.
  @discardableResult
  mutating func insert(_ id: String) -> Bool {
    guard ids.insert(id).inserted else { return false }

    order.append(id)
    if order.count > capacity {
      ids.remove(order.removeFirst())
    }

    return true
  }
}
