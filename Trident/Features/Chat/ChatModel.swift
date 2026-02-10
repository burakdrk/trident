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
}

@Observable
final class ChatModel: HashableObject, @MainActor IntentEmitting {
  // MARK: - State

  private(set) var messages: Deque<ChatMessage> = []
  private(set) var cachedAttributedString: [ChatMessage.ID: NSAttributedString] = [:]
  private(set) var cachedHeights: [ChatMessage.ID: CGFloat] = [:]
  private(set) var isPaused = false
  private(set) var newMessageCount = 0
  private(set) var tpEmotes: [DataModels.Emote.ID: DataModels.Emote]
  var fittingWidth: CGFloat? {
    didSet {
      if oldValue != fittingWidth {
        cachedHeights.removeAll()
      }
    }
  }

  // MARK: - Intent

  enum Intent {
    case scrollToBottom
    case applySnapshot
  }

  var intent: Intent?

  // MARK: - Dependencies

  @ObservationIgnored @Dependency(\.continuousClock) private var clock
  @ObservationIgnored @Dependency(\.ircClient) private var chatClient
  private let buffer = MessageBuffer(pauseMax: Constants.maxMessages)
  private let recentsService = RecentMessagesService()
  let channel: Channel

  init(for channel: Channel, tpEmotes: [DataModels.Emote.ID: DataModels.Emote] = [:]) {
    self.channel = channel
    self.tpEmotes = tpEmotes
  }

  // MARK: - Actions

  func setIsPaused(_ val: Bool) {
    isPaused = val
  }

  func startReading() async {
//      let (recents, recentIDs) = await dependencies.recentsService.fetch(
//        for: dependencies.channel.loginName,
//        emotes: state.tpEmotes
//      )
//      update {
//        $0.messages.add(recents.reversed())
//      }
    let stream = await chatClient.subscribe(to: channel)

    for await message in stream {
      if Task.isCancelled { break }

      switch message {
      case let .message(msg):
        await handleIRCMessages(msg)
      case let .status(status):
        handleStatusMessages(status)
      }
    }
  }

  private func handleIRCMessages(_ msg: IncomingMessage) async {
    switch msg {
    case let .privateMessage(pm):
//     if recentIDs.contains(pm.id) {
//        continue
//     }

      let parser = ChatMessageParser(thirdPartyEmotes: tpEmotes)

      await buffer.add(
        parser.parse(pm: pm),
        paused: isPaused
      )
    default: break
    }
  }

  private func handleStatusMessages(_ status: IRCStreamEvent.ConnectionStatus) {}

  func startRendering() async {
    while !Task.isCancelled {
      try? await clock.sleep(for: Constants.batchSpeed)
      let pending = await buffer.pendingMessages
      newMessageCount = pending

      guard !isPaused else { continue }

      let batch = await buffer.flush()
      if !batch.isEmpty {
        await add(batch)
        emit(.applySnapshot)
      }
    }
  }

  private func add(_ newMessages: [ChatMessage]) async {
    for msg in newMessages {
      messages.prepend(msg)

      let attrString = await MessageProcessor.makeAttributedString(
        for: msg,
        font: UIFont.systemFont(ofSize: 16)
      )
      cachedAttributedString[msg.id] = attrString
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
