import DataModels
import Foundation
import SwiftUI

@Observable
final class FollowingRouter {
  enum Path: Hashable {
    case channel(Channel)
  }

  var path: [Path] = []
  let followListModel = FollowListModel()
}

struct FollowingRouterView: View {
  @Bindable var router: FollowingRouter

  var body: some View {
    NavigationStack(path: $router.path) {
      FollowList(model: router.followListModel)
        .navigationDestination(for: FollowingRouter.Path.self) { path in
          switch path {
          case .channel:
            EmptyView()
          }
        }
        .containerBackground(.clear, for: .navigation)
    }
  }
}
