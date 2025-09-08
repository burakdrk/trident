import SwiftUI

enum FollowingRoute: AppRouter.Route {
  case channel(name: String)

  @ViewBuilder
  var destination: some View {
    switch self {
    case let .channel(name):
      ChatRootView(channelName: name)
    }
  }
}

extension AppRouter {
  var followingPath: Binding<[FollowingRoute]> {
    Binding {
      self._path[.following] as? [FollowingRoute] ?? []
    } set: { newValue in
      self._path[.following] = newValue
    }
  }

  func pushToFollowing(_ r: FollowingRoute) {
    var newPath = _path[.following, default: []]
    newPath.append(r)
    _path[.following] = newPath
  }
}
