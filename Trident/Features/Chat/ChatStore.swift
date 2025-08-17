//
//  ChatStore.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-14.
//

import Dependencies
import Foundation
import Observation

@Observable
final class ChatStore: DataStore {
  struct State: Equatable {
    var channel = "moonmoon"
    var channelID = "121059319"
    var maxMessages = 1000
    var batchSpeed = 150 // milliseconds

    var isPaused = false
    var newMessageCount = 0
    var messages: [ChatMessage] = []
    var isConnected = false
    var lastError: String?
    var lastUpdateID: UUID = .init()
  }

  enum Action: Equatable {
    case start
    case stop
    case togglePause(Bool)

    case _connected(Bool)
    case _setNewCount(Int)
    case _flush([ChatMessage])
    case _error(String)
  }

  private(set) var state: State

  @ObservationIgnored
  @Dependency(\.emoteClient) private var emoteClient
  @ObservationIgnored
  @Dependency(\.liveChatClient) private var chatClient
  @ObservationIgnored
  @Dependency(\.continuousClock) private var clock

  // Workers
  private let buffer: MessageBuffer
  private var consumeTask: Task<Void, Never>?
  private var renderTask: Task<Void, Never>?

  init() {
    let state = State()
    buffer = MessageBuffer(pauseMax: state.maxMessages)
    self.state = state
  }

  deinit {
    Task { @MainActor [weak self] in
      self?.cancelWorkers()
    }
  }

  func dispatch(_ action: Action) {
    switch action {
    case .start:
      state.lastError = nil
      startWorkers()

    case .stop:
      cancelWorkers()
      state.isConnected = false
      state.newMessageCount = 0

    case let .togglePause(on):
      state.isPaused = on

    case let ._connected(ok):
      state.isConnected = ok

    case let ._setNewCount(n):
      state.newMessageCount = n

    case let ._flush(batch):
      state.messages.insert(contentsOf: batch, at: 0)

      // Compute deletes if overflow
      if state.messages.count > state.maxMessages {
        let overflow = state.messages.count - state.maxMessages
        state.messages.removeLast(overflow)
      }

      state.lastUpdateID = UUID()

    case let ._error(msg):
      state.lastError = msg
    }
  }
}

// MARK: - Workers

private extension ChatStore {
  func startWorkers() {
    consumeTask?.cancel()
    consumeTask = Task { [weak self] in
      guard let self else { return }

      do {
        let stream = try await self.chatClient.connect(joinTo: self.state.channel)
        let tpEmotes = await self.emoteClient.emotes(channelID: self.state.channelID)

        self.dispatch(._connected(true))

        for try await message in stream {
          if Task.isCancelled { break }

          switch message {
          case let .privateMessage(pm):
            await self.buffer.add(
              ChatMessage(pm: pm, thirdPartyEmotes: tpEmotes),
              paused: self.state.isPaused
            )
          case let .roomState(room):
            print(room)
          default:
            break
          }
        }
      } catch {
        self.dispatch(._error(String(describing: error)))
      }
    }

    renderTask?.cancel()
    renderTask = Task { [weak self] in
      guard let self else { return }

      while !Task.isCancelled {
        try? await self.clock.sleep(for: .milliseconds(self.state.batchSpeed))
        let pending = await self.buffer.pendingMessages
        self.dispatch(._setNewCount(pending))

        guard !self.state.isPaused else { continue }

        let batch = await self.buffer.flush()
        if !batch.isEmpty { self.dispatch(._flush(batch)) }
      }
    }
  }

  func cancelWorkers() {
    consumeTask?.cancel(); consumeTask = nil
    renderTask?.cancel(); renderTask = nil
  }
}
