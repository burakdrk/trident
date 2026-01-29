import DataModels
import Dependencies
import SwiftUI

struct StreamState: Equatable {
  var activeChannels: [Channel: ChatStore] = [:]
  var visibleChannel: Channel?
  var lastError: String?
}

struct StreamDependencies {
  @Dependency(\.ircClient) var chatClient
  @Dependency(\.assetClient) var assetClient
}

typealias StreamStore = Store<StreamState, StreamDependencies>

extension StreamStore {
  static let shared = StreamStore(initialState: .init(), dependencies: .init())

  func loadStream(for channel: Channel) async {
    guard state.activeChannels[channel] == nil else { return }

    do {
      await dependencies.chatClient.connect()
      try await dependencies.chatClient.join(to: channel)
      let tpEmotes = await dependencies.assetClient.emotes(channel.id)

      update {
        $0.activeChannels[channel] = ChatStore(
          initialState: .init(tpEmotes: tpEmotes),
          dependencies: .init(channel: channel)
        )
      }
    } catch {
      update { $0.lastError = error.localizedDescription }
    }
  }

  private func unloadStream(for channel: Channel) async {
    try? await dependencies.chatClient.part(from: channel)
    update { $0.activeChannels.removeValue(forKey: channel) }
  }
}

private enum StreamStoreKey: EnvironmentKey {
  static var defaultValue = StreamStore.shared
}

extension EnvironmentValues {
  var streamManager: StreamStore {
    get { self[StreamStoreKey.self] }
    set { self[StreamStoreKey.self] = newValue }
  }
}
