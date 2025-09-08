import SwiftUI

@MainActor
@Observable
final class AppRouter {
  @MainActor protocol Route: Codable, Hashable {}

  var selectedTab: RootTab = .following
  var presentedSheet: RootSheet?
  var presentedCover: RootCover?
  var _path: [RootTab: [any Route]] = RootTab.allCases.reduce(into: [:]) { partialResult, tab in
    partialResult[tab] = []
  }

  private nonisolated init() {}

  /// Pop the last route from the current tab's navigation path.
  func pop() {
    _ = _path[selectedTab]?.popLast()
  }

  /// Pop the last route from the specified tab's navigation path.
  func pop(tab: RootTab) {
    _ = _path[tab]?.popLast()
  }

  /// Pop all routes from the specified tab's navigation path.
  func popToRoot(tab: RootTab) {
    _path[tab]?.removeAll()
  }

  /// Present root-level sheet.
  func present(_ sheet: RootSheet) {
    presentedSheet = sheet
  }

  /// Present root-level cover.
  func present(_ cover: RootCover) {
    presentedCover = cover
  }

  /// Dismiss root-level sheet.
  func dismissSheet() {
    presentedSheet = nil
  }

  /// Dismiss root-level cover.
  func dismissCover() {
    presentedCover = nil
  }
}

// MARK: - Environment

extension AppRouter {
  nonisolated static let shared = AppRouter()
}

extension EnvironmentValues {
  @Entry var router = AppRouter.shared
}
