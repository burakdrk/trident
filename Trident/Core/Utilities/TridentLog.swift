import OSLog

enum TridentLog {
  // swiftlint:disable:next force_unwrapping
  private static let subsystem = Bundle.main.bundleIdentifier!

  /// Logs the application lifecycle events.
  static let main = Logger(subsystem: subsystem, category: "main")

  /// All logs related to tracking and analytics.
  static let statistics = Logger(subsystem: subsystem, category: "statistics")

  /// Logs for the UI state
  static let stores = Logger(subsystem: subsystem, category: "stores")
}
