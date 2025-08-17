//
//  LiveChatClient.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-14.
//

import Dependencies
import DependenciesMacros

@DependencyClient
struct LiveChatClient {
  var connect: @Sendable (_ joinTo: String?) async throws -> IRCClient.IRCMessageStream
  var disconnect: @Sendable () async -> Void
  var join: @Sendable (_ to: String) async throws -> Void
  var part: @Sendable (_ from: String) async throws -> Void
  var partAll: @Sendable () async throws -> Void
}

extension LiveChatClient: DependencyKey {
  static var liveValue: Self {
    let client = IRCClient()

    return Self(
      connect: { joinTo in try await client.connect(joinTo: joinTo) },
      disconnect: { await client.disconnect() },
      join: { to in try await client.join(to: to) },
      part: { from in try await client.part(from: from) },
      partAll: { try await client.partAll() }
    )
  }
}

extension DependencyValues {
  var liveChatClient: LiveChatClient {
    get { self[LiveChatClient.self] }
    set { self[LiveChatClient.self] = newValue }
  }
}
