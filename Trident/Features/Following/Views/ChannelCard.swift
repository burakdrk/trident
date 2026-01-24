import Models
import SwiftUI

struct ChannelCard: View {
  @Environment(\.theme) private var theme

  var channel: Channel

  var body: some View {
    VStack {
      Text(channel.displayName)
    }
    .frame(width: 300, height: 100)
    .background(theme.bgElev)
    .clipShape(.rect(cornerRadius: 8))
  }
}
