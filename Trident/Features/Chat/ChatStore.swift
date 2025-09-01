import Collections
import FactoryKit
import Foundation
import Observation
import UIKit

@Observable
final class ChatStore: DataStore {
  struct State: Equatable {
    var channel: String
    var channelID: String = "71092938"
    var fittingWidth: CGFloat?

    var isPaused = false
    var newMessageCount = 0
    var tpEmotes: [String: Emote] = [:]
    var isConnected = false
    var lastError: String?
  }

  enum Action: Equatable {
    case start
    case stop
    case togglePause(Bool)
    case setFittingWidth(CGFloat)
    case setThirdPartyEmotes([String: Emote])

    case _connected(Bool)
    case _setNewCount(Int)
    case _flush([ChatMessage])
    case _error(String)
  }

  private(set) var state: State
  private let maxMessages: Int
  private let batchSpeed: Duration
  let messages: MessageSource

  @ObservationIgnored @Injected(\.assetClient) private var assetClient
  @ObservationIgnored @Injected(\.ircClient) private var chatClient

  // Workers
  private let buffer: MessageBuffer
  @ObservationIgnored private var consumeTask: Task<Void, Never>?
  @ObservationIgnored private var renderTask: Task<Void, Never>?

  private var recentsService = RecentMessagesService()

  init(channel: String, batchSpeed: Duration = .milliseconds(150), maxMessages: Int = 500) {
    buffer = MessageBuffer(pauseMax: maxMessages)
    state = State(channel: channel)
    self.maxMessages = maxMessages
    self.batchSpeed = batchSpeed
    messages = MessageSource(capacity: maxMessages)
  }

  deinit {
    print("Deinit ChatStore")
    consumeTask?.cancel()
    renderTask?.cancel()
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
      Task { await chatClient.disconnect() }

    case .togglePause(let on):
      state.isPaused = on

    case .setFittingWidth(let width):
      state.fittingWidth = width

    case .setThirdPartyEmotes(let emotes):
      state.tpEmotes = emotes

    case ._connected(let ok):
      state.isConnected = ok

    case ._setNewCount(let n):
      state.newMessageCount = n

    case ._flush(let batch):
      messages.add(batch, fittingWidth: state.fittingWidth)

    case ._error(let msg):
      state.lastError = msg
    }
  }
}

// MARK: - Workers

extension ChatStore {
  private func connect() async throws -> (IRCClientType.IRCMessageStream, Set<String>) {
    let stream = try await chatClient.connect()
    try await chatClient.join(to: state.channel)

    let tpEmotes = await assetClient.emotes(state.channelID)
    let (recents, recentIDs) = await recentsService.fetch(for: state.channel, emotes: tpEmotes)

    dispatch(.setThirdPartyEmotes(tpEmotes))
    dispatch(._flush(recents.reversed()))
    dispatch(._connected(true))

    return (stream, recentIDs)
  }

  private func startWorkers() {
    consumeTask?.cancel()
    consumeTask = Task { @Sendable [weak self, buffer] in
      do {
        guard let (stream, recentIDs) = try await self?.connect() else { return }

        for try await message in stream {
          if Task.isCancelled { break }

          switch message {
          case .privateMessage(let pm):
            if recentIDs.contains(pm.id) {
              continue
            }

            await buffer.add(
              ChatMessage(pm: pm, thirdPartyEmotes: self?.state.tpEmotes ?? [:]),
              paused: self?.state.isPaused ?? false
            )
          default: break
          }
        }
      } catch {
        self?.dispatch(._error(String(describing: error)))
      }

      print("Consume task died")
    }

    renderTask?.cancel()
    renderTask = Task { @Sendable [weak self, buffer, batchSpeed] in
      while !Task.isCancelled {
        guard let self else { break }

        try? await Task.sleep(for: batchSpeed)
        let pending = await buffer.pendingMessages
        dispatch(._setNewCount(pending))

        guard !state.isPaused else { continue }

        let batch = await buffer.flush()
        if !batch.isEmpty { dispatch(._flush(batch)) }
      }

      print("Render task died")
    }
  }

  private func cancelWorkers() {
    consumeTask?.cancel(); consumeTask = nil
    renderTask?.cancel(); renderTask = nil
  }
}
