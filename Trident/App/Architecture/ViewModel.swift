import SwiftUI
import Utilities

@Observable @dynamicMemberLookup
final class ViewModel<State: Equatable, Intent: Equatable, Dependencies>: HashableObject {
  private(set) var state: State
  var intent: Intent?
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

  /// For atomically updating state properties.
  /// - Parameter body: Updater function that mutates the state
  func update(_ body: (inout State) -> Void) {
    var newState = state
    body(&newState)
    state = newState
  }

  func observeIntent(perform handle: @MainActor @escaping (Intent) -> Void) {
    _ = withObservationTracking {
      self.intent
    } onChange: { [weak self] in
      DispatchQueue.main.async {
        guard let self else { return }
        defer { self.observeIntent(perform: handle) }

        guard let intent = self.intent else { return }
        handle(intent)
        self.intent = nil
      }
    }
  }
}

protocol IntentEmitting: Observable, AnyObject {
  associatedtype Intent: Equatable
  var intent: Intent? { get set }
}

extension IntentEmitting {
  func emit(_ intent: Intent) {
    self.intent = intent
  }

  func observeIntent(perform handle: @MainActor @escaping (Intent) -> Void) {
    let weakSelf = WeakBox(value: self)

    _ = withObservationTracking {
      self.intent
    } onChange: { [weakSelf] in
      Task { @MainActor in
        guard let self = weakSelf.value else { return }
        defer { self.observeIntent(perform: handle) }

        guard let intent = self.intent else { return }
        handle(intent)
        self.intent = nil
      }
    }
  }
}

/// Convenience type to use with models that have no intent.
enum NoIntent: Equatable {}

// MARK: - Intent View Modifier

private nonisolated struct OnIntentModifier<
  State: Equatable,
  Intent: Equatable,
  Dependencies
>: ViewModifier {
  let model: ViewModel<State, Intent, Dependencies>
  let handle: (Intent) -> Void

  func body(content: Content) -> some View {
    content
      .onChange(of: model.intent) { _, intent in
        guard let intent else { return }
        handle(intent)
        model.intent = nil
      }
  }
}

extension View {
  nonisolated func onIntent<Intent: Equatable>(
    from model: ViewModel<some Equatable, Intent, some Any>,
    perform handle: @escaping (Intent) -> Void
  ) -> some View {
    modifier(OnIntentModifier(model: model, handle: handle))
  }
}
