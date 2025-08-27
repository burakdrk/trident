import Foundation

protocol Route: Hashable, Codable {}

enum ExploreRoute: Route {
  case channel(name: String)
}

enum UserRoute: Route {
  case account
  case settings
  case logs
  case licenses
}

enum SearchRoute: Route {
  case channel(name: String)
}

enum FollowingRoute: Route {
  case channel(name: String)
}
