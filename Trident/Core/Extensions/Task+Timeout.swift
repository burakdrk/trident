import Foundation

extension Task where Success == Never, Failure == Never {
  private static func race<T: Sendable>(
    _ lhs: @Sendable @escaping () async throws -> T,
    _ rhs: @Sendable @escaping () async throws -> T
  ) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
      group.addTask { try await lhs() }
      group.addTask { try await rhs() }

      defer { group.cancelAll() }

      // swiftlint:disable:next force_unwrapping
      return try await group.next()!
    }
  }

  static func performWithTimeout<T: Sendable>(
    of timeout: Duration,
    _ work: @Sendable @escaping () async throws -> T
  ) async throws -> T {
    try await race(
      work,
      {
        try await Task.sleep(until: .now + timeout)
        throw TimeoutError.timedOut
      }
    )
  }
}

enum TimeoutError: LocalizedError {
  case timedOut

  var errorDescription: String? {
    switch self {
    case .timedOut:
      "Operation timed out"
    }
  }
}
