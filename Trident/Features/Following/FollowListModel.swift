import Foundation

@MainActor
@Observable
final class FollowListModel {
  let channels = Channel.mockList
}
