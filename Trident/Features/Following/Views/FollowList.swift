import SwiftUI

struct FollowList: View {
  @Environment(\.router) private var router
  @Namespace var animation
  let channels = ["xqc", "forsen", "moonmoon"]

  var body: some View {
    ScrollView {
      LazyVStack {
        ForEach(channels, id: \.self) { channel in
          ChannelCard(channel: channel)
            .onTapGesture {
              router.present(.streams(
                channels: channels,
                selectedChannel: channel,
                animation: animation
              ))
            }
            .matchedTransitionSource(id: channel, in: animation)
        }
      }
    }
  }
}
