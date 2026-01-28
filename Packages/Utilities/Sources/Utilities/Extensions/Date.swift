import Foundation

public extension Date {
  init?(iso8601String: String) {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    guard let date = formatter.date(from: iso8601String) else {
      return nil
    }
    self = date
  }

  /// Initializes a Date from a Unix timestamp in milliseconds.
  init(timestamp: Int) {
    self = Date(timeIntervalSince1970: TimeInterval(timestamp) / 1_000.0)
  }

  var formattedTime: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    // formatter.dateFormat = "hh:mm a" // 12-hour format with AM/PM
    return formatter.string(from: self)
  }
}
