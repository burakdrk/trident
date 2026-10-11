import DataModels
import Dependencies
import SwiftUI

private enum Constants {
  static let pollInterval: Duration = .seconds(10)
}

@Observable
final class StreamManagerModel {
  // MARK: - State

  private(set) var activeChannels: [Channel: ChatModel] = [:]
  private(set) var invisibleSince: [Channel: Date] = [:]
  private(set) var favoriteChannels: [Channel] = Channel.mockList

  /// Why a channel couldn't be loaded, until a later load succeeds.
  private(set) var loadFailures: [Channel: String] = [:]

  var visibleChannel: Channel? {
    didSet {
      if let old = oldValue, old != visibleChannel { invisibleSince[old] = now }
      if let visibleChannel { invisibleSince[visibleChannel] = nil }
    }
  }

  // MARK: - Dependencies

  @ObservationIgnored @Dependency(\.ircClient) private var chatClient
  @ObservationIgnored @Dependency(\.assetClient) private var assetClient
  @ObservationIgnored @Dependency(\.continuousClock) private var clock
  @ObservationIgnored @Dependency(\.date.now) private var now

  @ObservationIgnored private var loading: Set<Channel> = []
  @ObservationIgnored private let idleTimeout: TimeInterval

  /// How long a channel's chat stays loaded after it scrolls out of view.
  static let defaultIdleTimeout: TimeInterval = 5 * 60

  init(idleTimeout: TimeInterval = StreamManagerModel.defaultIdleTimeout) {
    self.idleTimeout = idleTimeout
  }

  // MARK: - Actions

  func loadStream(for channel: Channel) async {
    // Scrolling back and forth restarts the caller's task. Without this a second load would
    // replace the chat the first one just created.
    guard activeChannels[channel] == nil, loading.insert(channel).inserted else { return }
    defer { loading.remove(channel) }

    loadFailures[channel] = nil

    await chatClient.connect()

    do {
      try await chatClient.join(to: channel)
    } catch {
      loadFailures[channel] = error.localizedDescription
      return
    }

    let tpEmotes = await assetClient.emotes(channel.id)
    activeChannels[channel] = ChatModel(for: channel, tpEmotes: tpEmotes)
  }

  func startIdleStreamCleanup() async {
    while !Task.isCancelled {
      try? await clock.sleep(for: Constants.pollInterval)

      // Decide what to unload based on a stable snapshot.
      let channelsToUnload: [Channel] = invisibleSince.compactMap { channel, since in
        guard channel != visibleChannel else { return nil }
        guard activeChannels[channel] != nil else { return nil }
        guard now.timeIntervalSince(since) >= idleTimeout else { return nil }
        return channel
      }

      // Perform unloads.
      for channel in channelsToUnload {
        try? await chatClient.part(from: channel)
        activeChannels.removeValue(forKey: channel)
        invisibleSince[channel] = nil
      }
    }
  }
}
