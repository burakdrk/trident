//
//  LiveChatViewModel.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-04.
//

import Foundation

@MainActor
@Observable final class LiveChatViewModel {
    private let client: IRCClient
    private let buffer: MessageBuffer

    private var consumeTask: Task<Void, Never>?
    private var flushTask: Task<Void, Never>?

    private(set) var messages: [Message] = []
    var isPaused: Bool = false
    var newMessageCount: Int = 0

    init(buffer: MessageBuffer = .init()) {
        self.client = .init()
        self.buffer = buffer
    }

    func beginConsumingMessageStream() async throws {
        let messageStream = try await client.connect()
        try await client.join(to: "xqc")

        consumeTask = Task.detached(priority: .background) { [weak self, buffer] in
            do {
                for try await message in messageStream {
                    guard let self = self else { break }

                    switch message {
                    case .privateMessage(let msg):
                        let paused = await self.isPaused
                        await buffer.add(Message.fromPrivateMessage(pm: msg), paused: paused)
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
                    try await Task.sleep(nanoseconds: 150_000_000)
                    self.newMessageCount = await buffer.pauseBuffer.count

                    guard !self.isPaused else { continue }
                    self.messages = await buffer.renderList
                }
            } catch {}
        }
    }

    func stopConsuming() {
        consumeTask?.cancel()
        flushTask?.cancel()
    }
}
