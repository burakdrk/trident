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

  private nonisolated init() {}

  /// Push a route to specified tab.
  func push(to tab: AppTab, _ r: some Routable) {
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
  func present(_ presentable: Presentable, _ r: some Routable) {
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

extension AppRouter {
  nonisolated static let shared = AppRouter()
}

extension EnvironmentValues {
  @Entry var router = AppRouter.shared
}
