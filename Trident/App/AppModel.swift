import CasePaths
import DataModels
import Foundation
import SwiftUI

protocol PathProviding: Hashable {
  associatedtype Path: Hashable, CasePathable
  var path: [Path] { get }
}

protocol DestinationProviding: Hashable {
  associatedtype Destination: CasePathable
  var destination: Destination? { get }
}

// struct AppExperience {
//  @CasePathable
//  enum Destination {
//    case following(FollowingExperience)
//    case explore(ExploreExperience)
//    case user(UserExperience)
//    case search(SearchExperience)
//
//    func destinationView() -> some View {
//      switch self {
//      case .following:
//        EmptyView()
//      case .explore:
//        EmptyView()
//      case .user:
//        EmptyView()
//      case .search:
//        EmptyView()
//      }
//    }
//  }
//
//  var selectedTab: Destination = .following(.init())
// }

@Observable
final class AppModel<Dependencies> {
  private let dependencies: Dependencies

  init(dependencies: Dependencies) {
    self.dependencies = dependencies
  }
}

@Observable
final class FollowingExperience {
  enum Path: Hashable {
    case channel(Channel)
    case stream(initialChannel: Channel, channels: [Channel], animation: Namespace.ID)
  }

  var path: [Path] = []
  let followListModel = FollowListModel()

  func openStream(initialChannel: Channel, animation: Namespace.ID) {
    path.append(.stream(
      initialChannel: initialChannel,
      channels: followListModel.channels,
      animation: animation
    ))
  }
}

struct FollowingExperienceView: View {
  @Bindable var experience: FollowingExperience

  var body: some View {
    NavigationStack(path: $experience.path) {
      FollowList(model: experience.followListModel)
        .navigationDestination(for: FollowingExperience.Path.self) { path in
          switch path {
          case .channel:
            EmptyView()
          case let .stream(initialChannel, channels, animation):
            StreamView(
              initialChannel: initialChannel,
              channels: channels,
              animation: animation
            )
          }
        }
        .containerBackground(.clear, for: .navigation)
    }
  }
}
