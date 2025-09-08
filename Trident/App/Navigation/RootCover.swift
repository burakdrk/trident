import SwiftUI

enum RootCover: Hashable, Identifiable {
  case streams(channels: [String], selectedChannel: String, animation: Namespace.ID)

  @MainActor
  @ViewBuilder var destination: some View {
    switch self {
    case let .streams(channels, selectedChannel, animation):
      StreamView(selectedChannel: selectedChannel, channels: channels, animation: animation)
    }
  }

  var id: String {
    hashValue.formatted()
  }
}
