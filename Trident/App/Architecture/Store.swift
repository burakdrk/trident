import SwiftUI

@Observable @dynamicMemberLookup
final class Store<State: Equatable, Dependencies>: Equatable {
  private(set) var state: State
  @ObservationIgnored let dependencies: Dependencies

  init(initialState state: State, dependencies: Dependencies) {
    self.state = state
    self.dependencies = dependencies
  }

  /// Creates and returns a two-way binding for a state variable in the store.
  /// - Parameters:
  ///   - keyPath: Path of the state variable
  ///   - action: An optional side effect to execute after a set operation
  /// - Returns: Binding for the selected state variable
  func binding<T>(
    _ keyPath: WritableKeyPath<State, T>,
    action: ((T) -> Void)? = nil
  ) -> Binding<T> {
    Binding(
      get: { self.state[keyPath: keyPath] },
      set: { newValue in self.update { $0[keyPath: keyPath] = newValue }; action?(newValue) }
    )
  }

  subscript<T>(dynamicMember keyPath: KeyPath<State, T>) -> T {
    state[keyPath: keyPath]
  }

  func update(_ body: (inout State) -> Void) {
    var newState = state
    body(&newState)
    state = newState
  }

  static func == (lhs: Store<State, Dependencies>, rhs: Store<State, Dependencies>) -> Bool {
    lhs === rhs
  }
}
