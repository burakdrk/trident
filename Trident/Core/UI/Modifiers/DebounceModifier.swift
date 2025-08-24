//
//  DebounceModifier.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-24.
//

import AsyncAlgorithms
import SwiftUI

extension View {
  func debounce<T: Sendable & Equatable>(
    _ query: Binding<T>,
    using channel: AsyncChannel<T>,
    for duration: Duration,
    action: @Sendable @escaping (T) async -> Void
  ) -> some View {
    task {
      for await query in channel.debounce(for: duration) {
        await action(query)
      }
    }
    .task(id: query.wrappedValue) {
      await channel.send(query.wrappedValue)
    }
  }

  func debounce<T: Sendable & Equatable>(
    _ query: Binding<T>,
    using channel: AsyncChannel<T>,
    for duration: Duration,
    action: @Sendable @escaping () async -> Void
  ) -> some View {
    task {
      for await _ in channel.debounce(for: duration) {
        await action()
      }
    }
    .task(id: query.wrappedValue) {
      await channel.send(query.wrappedValue)
    }
  }
}
