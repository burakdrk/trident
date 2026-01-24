import Foundation

public extension URL {
  /// Only use this for hardcoded URLs.
  static func make(_ str: String) -> URL {
    guard let url = URL(string: str) else {
      fatalError("Invalid hardcoded URL string: \(str)")
    }

    return url
  }
}
