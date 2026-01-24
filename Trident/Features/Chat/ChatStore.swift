import Collections
import Dependencies
import Models
import Observation
import TwitchIRC
import UIKit

private enum Constants {
  static let maxMessages = 500
  static let batchSpeed: Duration = .milliseconds(150)
}

struct ChatState: Equatable {
  var fittingWidth: CGFloat?
  var isPaused = false
  var newMessageCount = 0
  var messages = MessageSource(capacity: Constants.maxMessages)
  var tpEmotes: [String: Models.Emote] = [:]
  var lastError: String?
}

struct ChatDependencies {
  @Dependency(\.continuousClock) var clock
  @Dependency(\.ircClient) var chatClient
  let channel: Channel
  let buffer = MessageBuffer(pauseMax: Constants.maxMessages)
  let recentsService = RecentMessagesService()
}

typealias ChatStore = Store<ChatState, ChatDependencies>

extension ChatStore {
  func togglePause(_ val: Bool) {
    update { $0.isPaused = val }
  }

  func setFittingWidth(_ val: CGFloat) {
    update { $0.fittingWidth = val }
  }

  func startReading() async {
    let stream = await dependencies.chatClient.subscribe(to: dependencies.channel)

    for try await message in stream {
      if Task.isCancelled { break }

      switch message {
      case let .message(msg):
        await handleIRCMessages(msg)
      case let .status(status):
        handleStatusMessages(status)
      }
    }

//      let (recents, recentIDs) = await dependencies.recentsService.fetch(
//        for: dependencies.channel.loginName,
//        emotes: state.tpEmotes
//      )
//      update {
//        $0.messages.add(recents.reversed(), fittingWidth: $0.fittingWidth)
//      }
  }

  private func handleIRCMessages(_ msg: IncomingMessage) async {
    switch msg {
    case let .privateMessage(pm):
      await dependencies.buffer.add(
        ChatMessage(pm: pm, thirdPartyEmotes: state.tpEmotes),
        paused: state.isPaused
      )

    //          if recentIDs.contains(pm.id) {
    //            continue
    //          }
    default: break
    }
  }

  private func handleStatusMessages(_ status: IRCStreamEvent.ConnectionStatus) {}

  func startRendering() async {
    while !Task.isCancelled {
      try? await dependencies.clock.sleep(for: Constants.batchSpeed)
      let pending = await dependencies.buffer.pendingMessages
      update { $0.newMessageCount = pending }

      guard !state.isPaused else { continue }

      let batch = await dependencies.buffer.flush()
      if !batch.isEmpty {
        update {
          $0.messages.add(batch, fittingWidth: $0.fittingWidth)
        }
      }
    }
  }
}
