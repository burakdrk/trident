import Foundation
import UIKit

final class UIChatViewController: UIViewController {
  typealias ChatDataSource = UITableViewDiffableDataSource<Int, ChatMessage>

  lazy var tableView: UITableView = {
    let tableView = UITableView()
    return tableView
  }()

  private var dataSource: ChatDataSource?

  var lastUpdateID = UUID()
  var backgroundColor: UIColor

  init(bg: UIColor) {
    backgroundColor = bg
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    configureTableView()
    configureDataSource()
  }

  override func viewSafeAreaInsetsDidChange() {
    super.viewSafeAreaInsetsDidChange()
    tableView.contentInset = UIEdgeInsets(
      top: view.safeAreaInsets.top + 5,
      left: 0,
      bottom: view.safeAreaInsets.bottom,
      right: 0
    )
  }

  private func configureTableView() {
    view.addAndFillSubview(tableView)
    tableView.register(
      MessageCell.self,
      forCellReuseIdentifier: MessageCell.reuseID
    )
    tableView.rowHeight = UITableView.automaticDimension
    tableView.separatorStyle = .none
    tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
    tableView.contentInsetAdjustmentBehavior = .never
    tableView.backgroundColor = backgroundColor
  }
}

// MARK: - Data Source

extension UIChatViewController {
  func applySnapshot(
    messages: [ChatMessage],
    animated: Bool = false,
    completion: (() -> Void)? = nil
  ) {
    var snapshot = NSDiffableDataSourceSnapshot<Int, ChatMessage>()
    snapshot.appendSections([0])
    snapshot.appendItems(messages, toSection: 0)

    dataSource?.apply(snapshot, animatingDifferences: animated, completion: completion)
  }

  private func configureDataSource() {
    let dataSource = ChatDataSource(tableView: tableView) { tableView, indexPath, item in
      let cell = tableView.dequeueReusableCell(
        withIdentifier: MessageCell.reuseID,
        for: indexPath
      )

      guard let cell = cell as? MessageCell else {
        return nil
      }

      cell.makeMessage(
        message: item,
        font: UIFont.systemFont(ofSize: 15)
      )

      return cell
    }

    dataSource.defaultRowAnimation = .none
    self.dataSource = dataSource
  }
}
