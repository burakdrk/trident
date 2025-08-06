//
//  IRCClient.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-04.
//

import Foundation
import TwitchIRC

typealias IRCMessageStream = AsyncThrowingStream<IncomingMessage, Error>

actor IRCClient {
    private let websocket: URLSessionWebSocketTask
    private var joinedChannels: Set<String> = []

    init(urlSession: URLSession = URLSession(configuration: .default)) {
        let url = URL(string: "wss://irc-ws.chat.twitch.tv:443")!
        websocket = urlSession.webSocketTask(with: url)
    }

    deinit {
        websocket.cancel(with: .goingAway, reason: .none)
    }

    func connect() async throws -> IRCMessageStream {
        websocket.resume()
        try await requestCapabilities()
        try await authenticate()

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    while true {
                        let messages = try await websocket.receiveMsg()
                        for msg in messages {
                            switch msg {
                            case .ping:
                                try await websocket.sendMsg(.pong)
                            case .join(let join):
                                joinedChannels.insert(join.channel)
                                continuation.yield(msg)
                            case .part(let part):
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
    }

    func disconnect() {
        websocket.cancel(with: .goingAway, reason: .none)
        joinedChannels = []
    }

    func join(to channel: String) async throws {
        try await websocket.sendMsg(.join(to: channel))
    }

    func part(from channel: String) async throws {
        guard joinedChannels.contains(channel) else { return }
        try await websocket.sendMsg(.part(from: channel))
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
        try await websocket.sendMsg(.capabilities([.tags, .commands]))

        let success = try await websocket.receiveMsg().contains(where: {
            if case .capabilities = $0 { true } else { false }
        })

        if !success {
            throw IRCError.failedToConnect
        }
    }

    private func authenticate() async throws {
        try await websocket.sendMsg(.pass(pass: "SCHMOOPIIE"))
        try await websocket.sendMsg(.nick(name: "justinfan28264"))

        let success = try await websocket.receiveMsg().contains(where: {
            if case .connectionNotice = $0 { true } else { false }
        })

        if !success {
            throw IRCError.failedToConnect
        }
    }
}
