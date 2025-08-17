//
//  IRCClient.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-04.
//

import Dependencies
import Foundation
import TwitchIRC

actor IRCClient {
  private let websocket: URLSessionWebSocketTask
  private var joinedChannels: Set<String> = []

  typealias IRCMessageStream = AsyncThrowingStream<IncomingMessage, Error>

  private var stream: IRCMessageStream?

  init() {
    guard let url = URL(string: "wss://irc-ws.chat.twitch.tv:443") else {
      fatalError("Invalid IRC WebSocket URL")
    }

    @Dependency(\.urlSession) var urlSession
    websocket = urlSession.webSocketTask(with: url)
  }

  deinit {
    websocket.cancel(with: .goingAway, reason: .none)
  }

  func connect(joinTo channel: String? = nil) async throws -> IRCMessageStream {
    if let existingStream = stream {
      try await partAll()
      if let channel = channel {
        try await join(to: channel)
      }

      return existingStream
    }

    websocket.resume()
    try await requestCapabilities()
    try await authenticate()

    if let channel = channel {
      try await join(to: channel)
    }

    let newStream = AsyncThrowingStream { continuation in
      Task {
        do {
          while true {
            let messages = try await self.receiveMsg()
            for msg in messages {
              switch msg {
              case .ping:
                try await self.sendMsg(.pong)
              case let .join(join):
                joinedChannels.insert(join.channel)
                continuation.yield(msg)
              case let .part(part):
                joinedChannels.remove(part.channel)
                continuation.yield(msg)
              default:
                continuation.yield(msg)
              }
            }
          }
        } catch {
          continuation.finish(throwing: error)
          disconnect()
        }
      }
    }

    stream = newStream
    return newStream
  }

  func disconnect() {
    websocket.cancel(with: .goingAway, reason: .none)
    joinedChannels = []
  }

  func join(to channel: String) async throws {
    try await sendMsg(.join(to: channel))
  }

  func part(from channel: String) async throws {
    guard joinedChannels.contains(channel) else { return }
    try await sendMsg(.part(from: channel))
  }

  func partAll() async throws {
    for chan in joinedChannels {
      try await part(from: chan)
    }
  }
}

// MARK: - Helpers

extension IRCClient {
  private func requestCapabilities() async throws {
    try await sendMsg(.capabilities([.tags, .commands]))

    let success = try await receiveMsg().contains(where: {
      if case .capabilities = $0 { true } else { false }
    })

    if !success {
      throw IRCError.failedToConnect
    }
  }

  private func authenticate() async throws {
    try await sendMsg(.pass(pass: "SCHMOOPIIE"))
    try await sendMsg(.nick(name: "justinfan28264"))

    let success = try await receiveMsg().contains(where: {
      if case .connectionNotice = $0 { true } else { false }
    })

    if !success {
      throw IRCError.failedToConnect
    }
  }

  private func sendMsg(_ twitchMessage: OutgoingMessage) async throws {
    try await websocket.send(.string(twitchMessage.serialize()))
  }

  private func receiveMsg() async throws -> [IncomingMessage] {
    let result = try await websocket.receive()
    if case let .string(msgStr) = result {
      return IncomingMessage.parse(ircOutput: msgStr).compactMap(\.message)
    } else {
      return []
    }
  }
}
