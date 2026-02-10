import DataModels
import Dependencies
import SwiftUI

private enum Constants {
  static let pollInterval: Duration = .seconds(10)
  static let idleTimeoutSeconds: TimeInterval = 10 // 5 * 60
}

@Observable
final class StreamManagerModel {
  // MARK: - State

  private(set) var activeChannels: [Channel: ChatModel] = [:]
  private(set) var invisibleSince: [Channel: Date] = [:]
  private(set) var favoriteChannels: [Channel] = Channel.mockList
  private(set) var lastError: String?
  var visibleChannel: Channel? {
    didSet {
      if let old = oldValue, old != visibleChannel { invisibleSince[old] = Date.now }
      if let visibleChannel { invisibleSince[visibleChannel] = nil }
    }
  }

  // MARK: - Dependencies

  @ObservationIgnored @Dependency(\.ircClient) private var chatClient
  @ObservationIgnored @Dependency(\.assetClient) private var assetClient
  @ObservationIgnored @Dependency(\.continuousClock) private var clock

  static let shared = StreamManagerModel()
  private init() {}

  // MARK: - Actions

  func loadStream(for channel: Channel) async {
    guard activeChannels[channel] == nil else { return }

    do {
      await chatClient.connect()
      try await chatClient.join(to: channel)
      let tpEmotes = await assetClient.emotes(channel.id)

      activeChannels[channel] = ChatModel(for: channel, tpEmotes: tpEmotes)
    } catch {
      lastError = error.localizedDescription
    }
  }

  func startIdleStreamCleanup() async {
    while !Task.isCancelled {
      try? await clock.sleep(for: Constants.pollInterval)

      // Decide what to unload based on a stable snapshot.
      let channelsToUnload: [Channel] = invisibleSince.compactMap { channel, since in
        guard channel != visibleChannel else { return nil }
        guard activeChannels[channel] != nil else { return nil }
        guard Date.now.timeIntervalSince(since) >= Constants.idleTimeoutSeconds else { return nil }
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

// MARK: - Environment

extension EnvironmentValues {
  @Entry var streamManager = StreamManagerModel.shared
}
