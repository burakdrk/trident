import Foundation
import Observation

@MainActor
protocol DataStore: Observable {
  associatedtype State: Equatable
  associatedtype Action

  var state: State { get }

  /// Dispatch an action to the store to mutate the state.
  func dispatch(_ action: Action)
}
