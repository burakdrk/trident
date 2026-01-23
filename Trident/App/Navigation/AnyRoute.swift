import SwiftUI

protocol Routable: View, Hashable, Identifiable {}

extension Routable where ID: Hashable {
  static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  func makeIdentity<each T: Hashable>(_ items: repeat each T) -> String {
    var hasher = Hasher()

    for item in repeat each items {
      hasher.combine(item)
    }

    return String(hasher.finalize())
  }
}

@MainActor
struct AnyRoute: @MainActor Hashable, @MainActor Identifiable {
  /// ID for equality check and hashable conformance.
  let id: AnyHashable

  /// Closure that creates the destination view.
  private let _destinationView: () -> AnyView

  private let _hash: (inout Hasher) -> Void
  private let _equals: (AnyRoute) -> Bool
  private let internalRoute: Any

  init<T: Routable>(_ route: T) {
    _destinationView = { AnyView(route) } // Type-erased route
    internalRoute = route // Actual route

    id = route.id

    _hash = { hasher in route.hash(into: &hasher) }
    _equals = { other in
      guard let otherRoute = other.internalRoute as? T else { return false }
      return route == otherRoute
    }
  }

  func destinationView() -> some View {
    _destinationView()
  }

  static func == (lhs: AnyRoute, rhs: AnyRoute) -> Bool {
    lhs._equals(rhs)
  }

  func hash(into hasher: inout Hasher) {
    _hash(&hasher)
  }
}
