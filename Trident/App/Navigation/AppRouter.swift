import SwiftUI

@MainActor
@Observable
final class AppRouter {
  enum Presentable {
    case sheet, cover
  }

  var selectedTab: AppTab = .following
  var presentedSheet: AnyRoute?
  var presentedCover: AnyRoute?
  var _path: [AppTab: [AnyRoute]] = AppTab.allCases.reduce(into: [:]) { partialResult, tab in
    partialResult[tab] = []
  }

  private init() {}

  static let shared = AppRouter()

  /// Push a route to specified tab.
  func push(to tab: AppTab, _ r: some RoutableView) {
    var newPath = _path[tab, default: []]
    newPath.append(AnyRoute(r))
    _path[tab] = newPath
  }

  /// Helper binding for path for usage with NavigationStack.
  func path(for tab: AppTab) -> Binding<[AnyRoute]> {
    Binding {
      self._path[tab] ?? []
    } set: { newValue in
      self._path[tab] = newValue
    }
  }

  /// Pop the last route from the current tab's navigation path.
  func pop() {
    _ = _path[selectedTab]?.popLast()
  }

  /// Pop the last route from the specified tab's navigation path.
  func pop(tab: AppTab) {
    _ = _path[tab]?.popLast()
  }

  /// Pop all routes from the specified tab's navigation path.
  func popToRoot(tab: AppTab) {
    _path[tab]?.removeAll()
  }

  /// Present an app-level view.
  func present(_ presentable: Presentable, _ r: some RoutableView) {
    switch presentable {
    case .sheet:
      presentedSheet = AnyRoute(r)
    case .cover:
      presentedCover = AnyRoute(r)
    }
  }

  /// Dismiss app-level view.
  func dismiss(_ presentable: Presentable) {
    switch presentable {
    case .sheet:
      presentedSheet = nil
    case .cover:
      presentedCover = nil
    }
  }
}

// MARK: - Environment

@MainActor
private enum AppRouterKey: EnvironmentKey {
  static var defaultValue = AppRouter.shared
}

@MainActor
extension EnvironmentValues {
  var router: AppRouter {
    get { self[AppRouterKey.self] }
    set { self[AppRouterKey.self] = newValue }
  }
}
