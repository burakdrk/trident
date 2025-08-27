import Foundation
import TwitchIRC

actor MockIRCClient: IRCClientType {
  enum Call: Equatable, Sendable {
    case connect(String?)
    case disconnect
    case join(String)
    case part(String)
    case partAll
  }

  private(set) var calls: [Call] = []
  private var continuation: IRCMessageStream.Continuation?
  private var cachedStream: IRCMessageStream?

  init(simulate: Bool = false) {
    guard simulate else { return }

    Task.detached { [weak self] in
      while true {
        if self == nil { break }
        await self?.sendIncoming(MockIRCClient.generateMessage(roomID: "12345678"))
        try? await Task.sleep(for: .seconds(0.5))
      }
    }
  }

  func connect() async throws -> IRCMessageStream {
    if let s = cachedStream { return s }

    let stream = IRCMessageStream { cont in
      Task { self.setContinuation(cont) }
    }
    cachedStream = stream

    return stream
  }

  func disconnect() {
    calls.append(.disconnect)
    finish()
  }

  func join(to channel: String) async throws {
    calls.append(.join(channel))
  }

  func part(from channel: String) async throws {
    calls.append(.part(channel))
  }

  func partAll() async throws {
    calls.append(.partAll)
  }
}

// MARK: - Test driver API

extension MockIRCClient {
  func sendIncoming(_ msg: IncomingMessage) {
    continuation?.yield(msg)
  }

  func sendMany(_ msgs: [IncomingMessage]) {
    for m in msgs {
      continuation?.yield(m)
    }
  }

  func finish(throwing error: Error? = nil) {
    if let error {
      continuation?.finish(throwing: error)
    } else {
      continuation?.finish()
    }
  }

  private func setContinuation(_ c: IRCMessageStream.Continuation) {
    continuation = c
  }
}

// MARK: - Simulation for Previews

extension MockIRCClient {
  /// Parameter: roomID of length 8
  static func generateMessage(roomID: String) -> IncomingMessage {
    let clientNonce = String.lowerRandomAlphanumeric(length: 32)
    let color = String.randomNumeric(length: 6)
    let userID = String.randomNumeric(length: 9)
    let sent = Date.now.timeIntervalSince1970 * 1_000

    return IncomingMessage
      .parse(
        ircOutput: "@badge-info=;badges=rplace-2023/1;client-nonce=\(clientNonce);color=#\(color);display-name=testuser;emotes=;first-msg=0;flags=;id=\(UUID().uuidString);mod=0;returning-chatter=0;room-id=\(roomID);subscriber=0;tmi-sent-ts=\(sent);turbo=0;user-id=\(userID);user-type= :testuser!testuser@testuser.tmi.twitch.tv PRIVMSG #testchannel :test message"
        // swiftlint:disable:next force_unwrapping
      ).first!.message!
  }
}
