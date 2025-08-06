//
//  LiveChatViewModel.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-04.
//

import Foundation
import SwiftUI

@MainActor
@Observable final class LiveChatViewModel {
    private let client: IRCClient
    private let emoteClient: ThirdPartyEmoteClient
    private let buffer: MessageBuffer

    private var consumeTask: Task<Void, Never>?
    private var flushTask: Task<Void, Never>?

    private(set) var messages: [RenderableMessage] = []
    private(set) var thirdPartyEmotes: [String: Emote] = [:]

    var position: ScrollPosition = .init(edge: .bottom)
    var isPaused: Bool { position.isPositionedByUser }
    var newMessageCount: Int = 0

    init(buffer: MessageBuffer = .init()) {
        self.client = .init()
        self.emoteClient = .init(channelID: "517475551", services: [
            FFZService(),
            BTTVService(),
            SevenTVService()
        ])

        self.buffer = buffer
    }

    func beginConsumingMessageStream() async throws {
        let messageStream = try await client.connect()
        try await client.join(to: "extraemily")
        thirdPartyEmotes = await emoteClient.emotes()

        consumeTask = Task.detached(priority: .background) { [weak self, buffer] in
            do {
                for try await message in messageStream {
                    guard let self = self else { break }

                    switch message {
                    case .privateMessage(let msg):
                        let paused = await self.isPaused
                        await buffer.add(Message.fromPrivateMessage(pm: msg), paused: paused)
                    case .roomState(let roomState):
                        print(roomState)
                    default:
                        break
                    }
                }
            } catch {}
        }

        flushTask = Task { @MainActor [weak self, buffer] in
            do {
                while !Task.isCancelled {
                    guard let self = self else { break }
                    try await Task.sleep(nanoseconds: 100_000_000)
                    self.newMessageCount = await buffer.pendingMessages

                    guard !self.isPaused else { continue }
                    let renderMessages = await buffer.renderList

                    let parser = MessageParser(messages: renderMessages, thirdPartyEmotes: self.thirdPartyEmotes)
                    self.messages = await parser.renderStream
                }
            } catch {}
        }
    }

    func stopConsuming() {
        consumeTask?.cancel()
        flushTask?.cancel()
    }
}
