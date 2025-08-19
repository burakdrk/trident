//
//  ChatViewController.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-06.
//

import Foundation
import SwiftUI
import UIKit

struct ChatViewController: UIViewControllerRepresentable, Equatable {
  var messages: [ChatMessage]
  var isPaused: Bool
  var lastUpdateID: UUID
  var togglePause: (Bool) -> Void

  // Only update view when lastUpdateID or isPaused changes
  nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
    return lhs.lastUpdateID == rhs.lastUpdateID
      && lhs.isPaused == rhs.isPaused
  }

  func makeUIViewController(context: Context) -> UIChatViewController {
    let vc = UIChatViewController()
    vc.tableView.delegate = context.coordinator
    context.coordinator.tableView = vc.tableView
    return vc
  }

  func updateUIViewController(_ vc: UIChatViewController, context: Context) {
    if vc.lastUpdateID == lastUpdateID {
      context.coordinator.parent = self
      context.coordinator.scrollToBottom(animated: true)
      return
    }

    vc.applySnapshot(messages: messages, animated: false) {
      vc.lastUpdateID = lastUpdateID
      context.coordinator.scrollToBottom(animated: false)
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(parent: self)
  }

  // MARK: - Coordinator

  final class Coordinator: NSObject, UITableViewDelegate {
    var parent: ChatViewController

    var lastY: CGFloat = .zero
    weak var tableView: UITableView?

    init(parent: ChatViewController) {
      self.parent = parent
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
      lastY = scrollView.contentOffset.y

      if !parent.isPaused {
        parent.togglePause(true)
      }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
      if case .changed = scrollView.panGestureRecognizer.state {
        return
      }

      let threshold: CGFloat = 20

      let bottomY = -scrollView.adjustedContentInset.top
      let y = scrollView.contentOffset.y
      let dy = y - lastY // moving towards bottom
      lastY = y

      let isUserScroll = scrollView.isDragging || scrollView.isDecelerating
      let nearBottom = y <= bottomY + threshold

      if isUserScroll, nearBottom, dy < 0 {
        parent.togglePause(false)
      }
    }

    func scrollToBottom(animated: Bool = false) {
      guard let tableView = tableView, !parent.isPaused else {
        return
      }

      if tableView.numberOfRows(inSection: 0) > 0 {
        let indexPath = IndexPath(row: 0, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
      }
    }
  }
}
