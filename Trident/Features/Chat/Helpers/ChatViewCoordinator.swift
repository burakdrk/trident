import Models
import UIKit

final class ChatViewCoordinator: NSObject, UITableViewDelegate {
  private let store: ChatStore

  var lastUpdateID = UUID()
  var lastBottomInset: CGFloat = 0
  var lastIsPaused = false
  var lastFittingWidth: CGFloat = 0

  // MARK: - Data Source

  typealias ChatDataSource = UITableViewDiffableDataSource<Int, ChatMessage>
  var dataSource: ChatDataSource?

  init(store: ChatStore) {
    self.store = store
  }

  func configureDataSource(_ view: UITableView) {
    let dataSource = ChatDataSource(tableView: view) { [weak self] tableView, indexPath, item in
      let cell = tableView.dequeueReusableCell(
        withIdentifier: MessageCell.reuseID,
        for: indexPath
      ) as? MessageCell

      guard let cell, let self else { return UITableViewCell() }
      cell.textView.attributedText = store.messages.cachedAttributedString[item.id]
      return cell
    }

    dataSource.defaultRowAnimation = .none
    self.dataSource = dataSource
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    guard let message = dataSource?.itemIdentifier(for: indexPath) else { return 50 }
    return store.messages.cachedHeight[message.id] ?? 50
  }

  // MARK: - Scrolling

  func scrollToBottom(_ tableView: UITableView, animated: Bool = false) {
    guard !store.state.isPaused else { return }

    let numberOfRows = tableView.numberOfRows(inSection: 0)
    guard numberOfRows > 0 else { return }

    let indexPath = IndexPath(row: numberOfRows - 1, section: 0)
    tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
  }

  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    if !store.state.isPaused {
      store.togglePause(true)
    }
  }

  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    if !decelerate {
      executeActionAtTheEnd(of: scrollView)
    }
  }

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    executeActionAtTheEnd(of: scrollView)
  }

  private func executeActionAtTheEnd(of scrollView: UIScrollView) {
    let threshold: CGFloat = 10
    let bottomEdge = scrollView.contentOffset.y + scrollView.frame.size.height
    if bottomEdge >= scrollView.contentSize.height - threshold {
      store.togglePause(false)
    }
  }
}
