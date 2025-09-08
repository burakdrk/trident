import SwiftUI

struct StreamState: StoreState {
  var activeChannels: [Channel] = []
}

struct StreamDependencies: StoreDependencies {}

typealias StreamStore = Store<StreamState, StreamDependencies>

extension StreamStore {
  static let shared = StreamStore()
}

struct StreamKey: @MainActor EnvironmentKey {
  @MainActor static var defaultValue = StreamStore.shared
}

extension EnvironmentValues {
  @MainActor
  var streamStore: StreamStore {
    get { self[StreamKey.self] }
    set { self[StreamKey.self] = newValue }
  }
}
