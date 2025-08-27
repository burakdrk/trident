import SwiftUI

extension Binding {
  /// Read `Value` from the state; on write, dispatch an Action.
  static func action<S, A>(
    state getState: @Sendable @escaping () -> S,
    keyPath: KeyPath<S, Value> & Sendable,
    send: @Sendable @escaping (A) -> Void,
    to action: @Sendable @escaping (Value) -> A
  ) -> Binding<Value> {
    .init(
      get: { getState()[keyPath: keyPath] },
      set: { newValue in send(action(newValue)) }
    )
  }
}
