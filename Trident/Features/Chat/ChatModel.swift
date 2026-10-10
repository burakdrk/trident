import Collections
import DataModels
import Dependencies
import Foundation
import TridentCore
import TwitchIRC
import UIKit
import Utilities

private enum Constants {
  static let maxMessages = 500
  static let batchSpeed: Duration = .milliseconds(150)
  static let rememberedIDs = 2_000
}

@Observable
final class ChatModel: HashableObject {
  /// What the chat can tell the user about its connection.
  enum Connection: Equatable {
    /// Never been live yet.
    case connecting

    case live

    /// Was live and lost the connection. Chat resumes by itself.
    case reconnecting
  }

  // MARK: - State

  private(set) var messages: Deque<ChatMessage> = []
  private(set) var cachedAttributedString: [ChatMessage.ID: NSAttributedString] = [:]
  private(set) var cachedHeights: [ChatMessage.ID: CGFloat] = [:]
  private(set) var isPaused = false
  private(set) var newMessageCount = 0
  private(set) var connection = Connection.connecting
  private(set) var tpEmotes: EmotesByName
  var fittingWidth: CGFloat? {
    didSet {
      if oldValue != fittingWidth {
        cachedHeights.removeAll()
      }
    }
  }

  // MARK: - Dependencies

  @ObservationIgnored @Dependency(\.continuousClock) private var clock
  @ObservationIgnored @Dependency(\.ircClient) private var chatClient
  @ObservationIgnored @Dependency(\.recentMessages) private var recentMessages
  private let buffer = MessageBuffer(pauseMax: Constants.maxMessages)
  private let parser: ChatMessageParser
  @ObservationIgnored private var seenIDs = RecentIDs(capacity: Constants.rememberedIDs)
  @ObservationIgnored private var hasBeenLive = false
  let channel: Channel

  init(for channel: Channel, tpEmotes: EmotesByName = [:]) {
    self.channel = channel
    self.tpEmotes = tpEmotes
    parser = ChatMessageParser(thirdPartyEmotes: tpEmotes)
  }

  // MARK: - Actions

  func setIsPaused(_ val: Bool) {
    isPaused = val
  }

  /// Run for as long as the chat is on screen. Safe to run again after it was cancelled: messages
  /// missed in between are filled in from the recent messages service.
  func startReading() async {
    // Subscribe first. Live messages queue up in the stream while the recents load, so none are
    // lost.
    let stream = await chatClient.subscribe(to: channel)
    await loadRecents()

    for await event in stream {
      if Task.isCancelled { break }

      switch event {
      case let .message(.privateMessage(pm)):
        await receive(pm)
      case .message:
        break
      case let .status(status):
        handle(status)
      }
    }
  }

  private func loadRecents() async {
    let recents = await recentMessages.fetch(channel.loginName, tpEmotes)
    guard !Task.isCancelled else { return }

    let fresh = recents.filter { seenIDs.insert($0.id) }
    await buffer.addRecents(fresh)
  }

  private func receive(_ pm: PrivateMessage) async {
    guard seenIDs.insert(pm.id) else { return }
    await buffer.add(parser.parse(pm: pm), paused: isPaused)
  }

  private func handle(_ status: IRCStreamEvent.ConnectionStatus) {
    switch status {
    case .authenticated:
      hasBeenLive = true
      connection = .live
    case .disconnected, .connecting, .connected, .failed:
      connection = hasBeenLive ? .reconnecting : .connecting
    }
  }

  func startRendering() async {
    while !Task.isCancelled {
      try? await clock.sleep(for: Constants.batchSpeed)
      let pending = await buffer.pendingMessages
      newMessageCount = pending

      guard !isPaused else { continue }

      let batch = await buffer.flush()
      if !batch.isEmpty {
        await add(batch)
      }
    }
  }

  private func add(_ newMessages: [ChatMessage]) async {
    // Build the strings before touching `messages`: the view re-renders when `messages` changes,
    // and a cell must never show up without its string.
    for msg in newMessages {
      cachedAttributedString[msg.id] = await MessageProcessor.makeAttributedString(
        for: msg,
        font: UIFont.systemFont(ofSize: 16)
      )
    }

    for msg in newMessages {
      messages.prepend(msg)
    }

    // Compute deletes if overflow
    guard messages.count > Constants.maxMessages else { return }

    let overflow = messages.count - Constants.maxMessages

    for _ in 1...overflow {
      if let deletedMessage = messages.popLast() {
        cachedAttributedString.removeValue(forKey: deletedMessage.id)
        cachedHeights.removeValue(forKey: deletedMessage.id)
      }
    }
  }
}
