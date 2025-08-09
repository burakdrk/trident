//
//  ChatViewModel.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-04.
//

import Collections
import Foundation

@MainActor
final class ChatViewModel {
    private let client: IRCClient
    private let emoteClient: ThirdPartyEmoteClient
    private let buffer: MessageBuffer

    private var bufferTask: Task<Void, Never>?
    private var renderTask: Task<Void, Never>?

    private(set) var thirdPartyEmotes: [String: Emote] = [:]

    let maxMessages: Int

    var messages: Deque<RenderableMessage> = []
    var isPaused: Bool = false
    var setNewMessageCount: ((Int) -> Void)?
    var onBatchFlush: (([RenderableMessage]) -> Void)?

    init() {
        self.client = .init()
        self.emoteClient = .init(channelID: "517475551", services: [
            FFZService(),
            BTTVService(),
            SevenTVService()
        ])

        self.maxMessages = 1000
        self.buffer = .init(pauseMax: maxMessages)
    }

    func beginConsumingMessageStream() async throws {
        let messageStream = try await client.connect()
        try await client.join(to: "extraemily")
        thirdPartyEmotes = await emoteClient.emotes()

        bufferTask = Task.detached(priority: .background) { [weak self, buffer] in
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

        renderTask = Task { @MainActor [weak self, buffer] in
            do {
                while !Task.isCancelled {
                    guard let self = self else { break }
                    try await Task.sleep(nanoseconds: 100_000_000)
                    self.setNewMessageCount?(await buffer.pendingMessages)

                    guard !self.isPaused else { continue }
                    let newMessages = await buffer.newMessages

                    let parser = MessageParser(messages: newMessages, thirdPartyEmotes: self.thirdPartyEmotes)
                    self.onBatchFlush?(await parser.renderStream)
                }
            } catch {}
        }
    }

    func stopConsuming() {
        bufferTask?.cancel()
        renderTask?.cancel()
    }
}
