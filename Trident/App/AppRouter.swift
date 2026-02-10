import DataModels
import SwiftUI

@Observable
final class AppRouter {
  var selectedTab: Tab = .following
  var streamRouter: StreamRouter?

  let followingRouter = FollowingRouter()

  func openStream(initialChannel: Channel, animation: Namespace.ID) {
    streamRouter = .init(initialChannel: initialChannel, animation: animation)
  }
}

// MARK: - Tabs

extension AppRouter {
  enum Tab: CaseIterable, Hashable {
    case following
    case user
    case search

    @ViewBuilder
    func destinationView(router: AppRouter) -> some View {
      switch self {
      case .following:
        FollowingRouterView(router: router.followingRouter)
      case .user:
        EmptyView()
      case .search:
        EmptyView()
      }
    }

    var name: LocalizedStringResource {
      switch self {
      case .following:
        .followingTab
      case .search:
        .searchTab
      case .user:
        .userTab
      }
    }

    func imageName(active: Bool = true) -> String {
      switch self {
      case .following:
        active ? "heart.fill" : "heart"
      case .search:
        "magnifyingglass"
      case .user:
        active ? "person.fill" : "person"
      }
    }
  }
}

// MARK: - Environment

extension AppRouter {
  static let shared = AppRouter()
}

extension EnvironmentValues {
  @Entry var router = AppRouter.shared
}
