import Foundation

public struct WeakBox<T: AnyObject>: @unchecked Sendable {
  public weak var value: T?

  public init(value: T) {
    self.value = value
  }
}
