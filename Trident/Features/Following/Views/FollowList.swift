import SwiftUI

struct FollowList: View {
  @Environment(\.router) private var router
  @Namespace private var animation

  let model: FollowListModel

  var body: some View {
    ScrollView {
      LazyVStack {
        ForEach(model.channels) { channel in
          ChannelCard(channel: channel)
            .onTapGesture {
              router.openStream(
                initialChannel: channel,
                animation: animation
              )
            }
            .matchedTransitionSource(id: channel, in: animation)
        }
      }
    }
    .navigationTitle(.followingTab)
  }
}
