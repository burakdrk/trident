import Collections
import FactoryKit
import Observation
import UIKit

@MainActor
@Observable
final class ChatStore {
  struct State: Equatable {
    var channel: String?
    var channelID: String = "71092938"
    var fittingWidth: CGFloat?

    var isPaused = false
    var newMessageCount = 0
    var tpEmotes: [String: Emote] = [:]
    var isConnected = false
    var lastError: String?
  }

  enum Action: Equatable {
    case start(String)
    case stop
    case togglePause(Bool)
    case setFittingWidth(CGFloat)
    case setThirdPartyEmotes([String: Emote])

    case _connected(Bool)
    case _setNewCount(Int)
    case _flush([ChatMessage])
    case _error(String)
  }

  private(set) var state = State()
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

  init(batchSpeed: Duration = .milliseconds(150), maxMessages: Int = 500) {
    buffer = MessageBuffer(pauseMax: maxMessages)
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
    case let .start(channelName):
      state.lastError = nil
      startWorkers(channelName)

    case .stop:
      cancelWorkers()
      state.isConnected = false
      state.newMessageCount = 0
      Task { await chatClient.disconnect() }

    case let .togglePause(on):
      state.isPaused = on

    case let .setFittingWidth(width):
      state.fittingWidth = width

    case let .setThirdPartyEmotes(emotes):
      state.tpEmotes = emotes

    case let ._connected(ok):
      state.isConnected = ok

    case let ._setNewCount(n):
      state.newMessageCount = n

    case let ._flush(batch):
      messages.add(batch, fittingWidth: state.fittingWidth)

    case let ._error(msg):
      state.lastError = msg
    }
  }
}

// MARK: - Workers

extension ChatStore {
  func connect(to channel: String) async throws -> (IRCClientType.IRCMessageStream, Set<String>) {
    let stream = try await chatClient.connect()
    try await chatClient.join(to: channel)

    let tpEmotes = await assetClient.emotes(state.channelID)
    let (recents, recentIDs) = await recentsService.fetch(for: channel, emotes: tpEmotes)

    dispatch(.setThirdPartyEmotes(tpEmotes))
    dispatch(._flush(recents.reversed()))
    dispatch(._connected(true))

    return (stream, recentIDs)
  }

  private func startWorkers(_ channel: String) {
    consumeTask?.cancel()
    consumeTask = Task { @Sendable [weak self, buffer] in
      do {
        guard let (stream, recentIDs) = try await self?.connect(to: channel) else { return }

        for try await message in stream {
          if Task.isCancelled { break }

          switch message {
          case let .privateMessage(pm):
            if recentIDs.contains(pm.id) {
              continue
            }

            print(pm.channel)

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
