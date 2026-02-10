import DataModels
import Foundation
import SwiftUI
import Utilities

@Observable
final class StreamRouter: Identifiable {
  enum Path: Hashable {
    case empty
  }

  var path: [Path] = []

  let initialChannel: Channel
  let animation: Namespace.ID

  init(initialChannel: Channel, animation: Namespace.ID) {
    self.initialChannel = initialChannel
    self.animation = animation
  }
}

struct StreamRouterView: View {
  @Environment(\.streamManager) private var streamManager
  @Bindable var router: StreamRouter

  var body: some View {
    NavigationStack(path: $router.path) {
      StreamManagerView()
        .navigationDestination(for: StreamRouter.Path.self) { path in
          switch path {
          case .empty:
            EmptyView()
          }
        }
        .containerBackground(.clear, for: .navigation)
    }
    .toolbar(.hidden, for: .tabBar)
    .onAppear {
      streamManager.visibleChannel = router.initialChannel
    }
    .onDisappear {
      streamManager.visibleChannel = nil
    }
    .navigationTransition(
      .zoom(
        sourceID: streamManager.visibleChannel ?? router.initialChannel, in: router.animation
      ))
  }
}
