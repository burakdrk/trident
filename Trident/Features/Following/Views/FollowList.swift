import SwiftUI

struct FollowList: View {
  @Environment(\.router) private var router
  @Namespace var animation

  let channels = Channel.mockList

  var body: some View {
    ScrollView {
      LazyVStack {
        ForEach(channels) { channel in
          ChannelCard(channel: channel)
            .onTapGesture {
              router.present(
                .cover,
                StreamView(initialChannel: channel, channels: channels, animation: animation)
              )
            }
            .matchedTransitionSource(id: channel, in: animation)
        }
      }
    }
    .navigationTitle(.followingTab)
  }
}
