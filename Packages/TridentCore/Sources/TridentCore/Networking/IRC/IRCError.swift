import Foundation

enum IRCError: LocalizedError {
  case failedToConnect
  case notConnected
  case timedOut
  case serverRequestedReconnect

  var errorDescription: String? {
    switch self {
    case .failedToConnect:
      "Failed to connect to the chat"
    case .notConnected:
      "Not connected to the chat"
    case .timedOut:
      "Connecting to the chat timed out"
    case .serverRequestedReconnect:
      "Twitch asked us to reconnect"
    }
  }
}
