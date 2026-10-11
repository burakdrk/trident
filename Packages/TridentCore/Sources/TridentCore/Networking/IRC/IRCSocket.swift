import Dependencies
import Foundation
import Utilities

private enum Constants {
  static let wsUrl = "wss://irc-ws.chat.twitch.tv:443"
}

/// A text-frame connection to Twitch's IRC server. Exists so the client can be tested without a
/// network.
protocol IRCSocket: AnyObject, Sendable {
  func send(_ text: String) async throws

  /// Waits for the next text frame. Throws when the connection drops or `close()` is called.
  func receive() async throws -> String

  /// Closes the connection. Any pending `receive()` must throw.
  func close()
}

struct IRCSocketFactory: Sendable {
  var make: @Sendable () -> any IRCSocket
}

extension IRCSocketFactory: DependencyKey {
  static var liveValue: Self {
    Self {
      @Dependency(\.urlSession) var urlSession
      return URLSessionIRCSocket(
        task: urlSession.webSocketTask(with: URL.make(Constants.wsUrl))
      )
    }
  }
}

extension DependencyValues {
  var ircSocketFactory: IRCSocketFactory {
    get { self[IRCSocketFactory.self] }
    set { self[IRCSocketFactory.self] = newValue }
  }
}

// MARK: - Live

private final class URLSessionIRCSocket: IRCSocket {
  private let task: URLSessionWebSocketTask

  init(task: URLSessionWebSocketTask) {
    self.task = task
    task.resume()
  }

  func send(_ text: String) async throws {
    try await task.send(.string(text))
  }

  func receive() async throws -> String {
    while true {
      if case let .string(text) = try await task.receive() {
        return text
      }
    }
  }

  func close() {
    task.cancel(with: .goingAway, reason: nil)
  }
}
