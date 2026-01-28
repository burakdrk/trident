import Foundation

protocol Mockable {
  associatedtype MockType

  static var mock: MockType { get }
  static var mockList: [MockType] { get }
}

extension Mockable {
  static var mockList: [MockType] { [] }
}
