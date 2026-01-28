import OSLog

public enum TridentLog {
  // swiftlint:disable:next force_unwrapping
  private static let subsystem = Bundle.main.bundleIdentifier!

  /// Logs the application lifecycle events.
  public static let main = Logger(subsystem: subsystem, category: "main")

  /// All logs related to tracking and analytics.
  public static let statistics = Logger(subsystem: subsystem, category: "statistics")

  /// Logs for the UI state
  public static let stores = Logger(subsystem: subsystem, category: "stores")
}
