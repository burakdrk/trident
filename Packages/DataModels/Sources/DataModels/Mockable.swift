import Foundation

public protocol Mockable {
  associatedtype MockType

  static var mock: MockType { get }
  static var mockList: [MockType] { get }
}

public extension Mockable {
  static var mockList: [MockType] { [] }
}
