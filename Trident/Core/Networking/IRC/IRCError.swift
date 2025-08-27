import Foundation

enum IRCError: LocalizedError {
  case failedToConnect
  case alreadyConnected

  var errorDescription: String? {
    switch self {
    case .failedToConnect:
      "Failed to connect to the chat"
    case .alreadyConnected:
      "Already connected to the chat"
    }
  }
}
