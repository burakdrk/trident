//
//  Store.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-14.
//

import Foundation
import Observation

@MainActor
protocol DataStore: Observable {
  associatedtype State: Equatable
  associatedtype Action: Equatable

  var state: State { get }

  /// Dispatch an action to the store.
  func dispatch(_ action: Action)
}
