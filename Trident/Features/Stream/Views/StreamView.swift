import SwiftUI

struct StreamView: View {
  @State private var visiblePageId: String?

  let selectedChannel: String
  let channels: [String]
  let animation: Namespace.ID

  var body: some View {
    ScrollView(.horizontal) {
      LazyHStack(spacing: 0) {
        ForEach(channels, id: \.self) { channel in
          ChatRootView(channelName: channel)
            .containerRelativeFrame(.horizontal)
        }
      }
      .scrollTargetLayout()
    }
    .scrollTargetBehavior(.paging)
    .scrollPosition(id: $visiblePageId)
    .scrollIndicators(.hidden)
    .onAppear {
      visiblePageId = selectedChannel
    }
    .onChange(of: visiblePageId) { oldValue, newValue in
      if let oldId = oldValue {
        print("👍 View Disappeared: \(oldId)")
      }
      if let newId = newValue {
        print("✅ View Appeared: \(newId)")
      }
    }
    .navigationTransition(.zoom(sourceID: visiblePageId ?? selectedChannel, in: animation))
  }
}

#Preview {
  @Previewable @Namespace var animation
  StreamView(selectedChannel: "forsen", channels: ["forsen"], animation: animation)
}
