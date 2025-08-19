//
//  Tabs.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-17.
//

import Foundation

enum Tabs: CaseIterable, Hashable {
  case following
  case top
  case search
  case user

  var name: String {
    switch self {
    case .following:
      return "Following"
    case .top:
      return "Top"
    case .search:
      return "Search"
    case .user:
      return "User"
    }
  }

  var imageName: String {
    switch self {
    case .following:
      return "heart"
    case .top:
      return "safari"
    case .search:
      return "magnifyingglass"
    case .user:
      return "person"
    }
  }

  var activeImageName: String {
    if self == .search {
      return imageName
    }

    return "\(imageName).fill"
  }
}
