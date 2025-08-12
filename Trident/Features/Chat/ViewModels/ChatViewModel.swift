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

  typealias BatchFlushHandler = @MainActor @Sendable ([RenderableMessage]) ->
    Void
  typealias NewCountHandler = @MainActor @Sendable (Int) -> Void
  var onBatchFlush: BatchFlushHandler?
  var setNewMessageCount: NewCountHandler?

  init() {
    client = .init()
    emoteClient = .init(
      channelID: "22484632",
      services: [
        FFZService(),
        BTTVService(),
        SevenTVService()
      ]
    )

    maxMessages = 1000
    buffer = .init(pauseMax: maxMessages)
  }

  deinit {
    bufferTask?.cancel()
    renderTask?.cancel()
  }

  func beginConsumingMessageStream() async throws {
    let messageStream = try await client.connect(joinTo: "forsen")
    thirdPartyEmotes = await emoteClient.emotes()

    bufferTask = Task { [weak self, buffer] in
      do {
        for try await message in messageStream {
          guard let self = self else { break }

          switch message {
          case let .privateMessage(msg):
            await buffer.add(
              Message.fromPrivateMessage(privateMsg: msg),
              paused: self.isPaused
            )
          case let .roomState(roomState):
            print(roomState)
          default:
            break
          }
        }
      } catch {}
    }

    renderTask = Task { [weak self, buffer] in
      do {
        while !Task.isCancelled {
          guard let self = self else { break }
          try await Task.sleep(nanoseconds: 100_000_000)
          self.setNewMessageCount?(await buffer.pendingMessages)

          guard !self.isPaused else { continue }
          let newMessages = await buffer.newMessages

          let parser = MessageParser(
            messages: newMessages,
            thirdPartyEmotes: self.thirdPartyEmotes
          )
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
