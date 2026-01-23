import Foundation

enum IRCError: LocalizedError {
  case failedToConnect
  case alreadyConnected
  case alreadyConnecting

  var errorDescription: String? {
    switch self {
    case .failedToConnect:
      "Failed to connect to the chat"
    case .alreadyConnected:
      "Already connected to the chat"
    case .alreadyConnecting:
      "Already connecting to the chat"
    }
  }
}
