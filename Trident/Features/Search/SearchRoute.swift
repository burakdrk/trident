import SwiftUI

enum SearchRoute: AppRouter.Route {
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
  var searchPath: Binding<[SearchRoute]> {
    Binding {
      self._path[.search] as? [SearchRoute] ?? []
    } set: { newValue in
      self._path[.search] = newValue
    }
  }

  func pushToSearch(_ r: SearchRoute) {
    var newPath = _path[.search, default: []]
    newPath.append(r)
    _path[.search] = newPath
  }
}
