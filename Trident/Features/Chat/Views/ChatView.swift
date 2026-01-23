import Collections
import SwiftUI
import UIKit

struct ChatView: UIViewRepresentable {
  let store: ChatStore
  let bottomInset: CGFloat

  func makeUIView(context: Context) -> UITableView {
    let view = UITableView()
    view.register(MessageCell.self, forCellReuseIdentifier: MessageCell.reuseID)
    view.separatorStyle = .none
    view.contentInsetAdjustmentBehavior = .never
    view.backgroundColor = UIColor(context.environment.theme.bg)
    view.delegate = context.coordinator
    context.coordinator.configureDataSource(view)
    return view
  }

  func updateUIView(_ uiView: UITableView, context: Context) {
    if context.coordinator.lastFittingWidth != uiView.bounds.width {
      store.setFittingWidth(uiView.bounds.width)
      context.coordinator.lastFittingWidth = uiView.bounds.width
    }

    if context.coordinator.lastBottomInset != bottomInset {
      uiView.contentInset = UIEdgeInsets(
        top: uiView.safeAreaInsets.top,
        left: 0,
        bottom: bottomInset + 8,
        right: 0
      )
      uiView.verticalScrollIndicatorInsets.bottom = bottomInset - uiView.safeAreaInsets.bottom
      context.coordinator.lastBottomInset = bottomInset
    }

    if context.coordinator.lastIsPaused != store.state.isPaused {
      context.coordinator.scrollToBottom(uiView, animated: true)
      context.coordinator.lastIsPaused = store.state.isPaused
    }

    if context.coordinator.lastUpdateID != store.messages.updateID {
      context.coordinator.dataSource?.apply(
        store.messages.snapshot,
        animatingDifferences: false
      ) {
        DispatchQueue.main.async {
          context.coordinator.scrollToBottom(uiView, animated: false)
          context.coordinator.lastUpdateID = store.messages.updateID
        }
      }
    }
  }

  func makeCoordinator() -> ChatViewCoordinator {
    ChatViewCoordinator(store: store)
  }
}
