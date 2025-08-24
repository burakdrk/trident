//
//  Routes.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-17.
//

import Foundation

enum ExploreRoute: Hashable, Codable {
  case channel(name: String)
}

enum UserRoute: Hashable, Codable {
  case account
  case settings
  case logs
  case licenses
}

enum SearchRoute: Hashable, Codable {
  case channels(query: String)
  case users(query: String)
}

enum FollowingRoute: Hashable, Codable {
  case channel(name: String)
}
