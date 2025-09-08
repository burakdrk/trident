import SwiftUI
#if DEBUG
import Difference
#endif

protocol StoreState: Equatable, Sendable { init() }
@MainActor protocol StoreDependencies: Sendable { init() }

@MainActor
@Observable
final class Store<State: StoreState, Dependencies: StoreDependencies> {
  private(set) var state: State
  @ObservationIgnored let deps = Dependencies()

  init(initialState state: State = .init()) {
    print("\(Self.self) init")
    self.state = state
  }

  func binding<T>(_ keyPath: KeyPath<State, T>, action: @escaping (T) -> Void) -> Binding<T> {
    Binding(
      get: { self.state[keyPath: keyPath] },
      set: { newValue in action(newValue) }
    )
  }

  deinit { print("\(Self.self) deinit") }

  func update(_ body: (inout State) -> Void) {
    var newState = state
    body(&newState)

    #if DEBUG
    print("State update: \(Self.self)")
    print(diff(newState, state).joined(separator: ", ")
      .replacingOccurrences(of: "Received:", with: "Before:")
      .replacingOccurrences(of: "Expected:", with: "After:")
    )
    #endif

    state = newState
  }
}
