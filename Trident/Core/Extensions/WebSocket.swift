//
//  WebSocket.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-04.
//

import Foundation
import TwitchIRC

extension URLSessionWebSocketTask {
    func sendMsg(_ twitchMessage: OutgoingMessage) async throws {
        try await self.send(.string(twitchMessage.serialize()))
    }

    func receiveMsg() async throws -> [IncomingMessage] {
        let result = try await self.receive()
        if case .string(let msgStr) = result {
            return IncomingMessage.parse(ircOutput: msgStr).compactMap(\.message)
        } else {
            return []
        }
    }
}
