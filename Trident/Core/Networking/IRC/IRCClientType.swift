import FactoryKit
import Foundation
import TwitchIRC

protocol IRCClientType: Sendable {
  typealias IRCMessageStream = AsyncThrowingStream<IncomingMessage, Error>

  func connect() async throws -> IRCMessageStream
  func disconnect() async
  func join(to channel: String) async throws
  func part(from channel: String) async throws
  func partAll() async throws
}

extension Container {
  var ircClient: Factory<IRCClientType> {
    self { IRCClient() }
      .cached
      .onTest { MockIRCClient() }
      .onPreview { IRCClient() }
  }
}
