//
//  Logger.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-17.
//

import OSLog

extension Logger {
  // swiftlint:disable:next force_unwrapping
  private static let subsystem = Bundle.main.bundleIdentifier!

  /// Logs the application lifecycle events.
  static let main = Logger(subsystem: subsystem, category: "main")

  /// All logs related to tracking and analytics.
  static let statistics = Logger(subsystem: subsystem, category: "statistics")
}
