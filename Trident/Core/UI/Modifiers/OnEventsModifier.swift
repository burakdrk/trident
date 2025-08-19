//
//  OnEventsModifier.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-17.
//

import SwiftUI

struct OnEventsModifier<E: Sendable>: ViewModifier {
  let stream: AsyncStream<E>
  let handler: @MainActor (E) -> Void

  func body(content: Content) -> some View {
    content.task {
      for await e in stream {
        handler(e)
      }
    }
  }
}

extension View {
  func onEvents<E: Sendable>(
    _ stream: AsyncStream<E>,
    perform: @escaping @MainActor (E) -> Void
  ) -> some View {
    modifier(OnEventsModifier(stream: stream, handler: perform))
  }
}
