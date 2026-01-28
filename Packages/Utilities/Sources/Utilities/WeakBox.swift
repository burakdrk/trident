import Foundation

public struct WeakBox<T: AnyObject> {
  public weak var value: T?

  public init(value: T) {
    self.value = value
  }
}
