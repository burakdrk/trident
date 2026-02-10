import BlurUIKit
import DataModels
import SwiftUI
import UIKit

private enum Constants {
  static let stickThreshold: CGFloat = 10
}

final class ChatViewController: UIViewController {
  private let model: ChatModel
  private var theme: ThemePalette

  /// Needs to come from SwiftUI because the message box is pushed to the safe area, but the height
  /// doesn't propagate down to UIKit.
  private var swiftUISafeAreaInsets: EdgeInsets

  nonisolated enum Section: Int {
    case main = 0
  }

  typealias DataSource = UITableViewDiffableDataSource<Section, ChatMessage>
  typealias Snapshot = NSDiffableDataSourceSnapshot<Section, ChatMessage>

  private let tableView = UITableView(frame: .zero, style: .plain)
  private lazy var dataSource = makeDataSource()
  private let topBlurView = VariableBlurView()
  private let bottomBlurView = VariableBlurView()

  init(model: ChatModel, theme: ThemePalette, swiftUISafeAreaInsets: EdgeInsets) {
    self.model = model
    self.theme = theme
    self.swiftUISafeAreaInsets = swiftUISafeAreaInsets

    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    configureTableView()
    configureBlur()
    setBackgroundColor()
    applySnapshot()
    setInsets()

    model.observeIntent { [weak self] intent in
      switch intent {
      case .scrollToBottom: self?.scrollToBottom(animated: true)
      case .applySnapshot: self?.applySnapshot()
      }
    }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()

    // Update model width info
    model.fittingWidth = tableView.bounds.width

    // Clamp blur views to the top/bottom safe area
    let bottomInset = swiftUISafeAreaInsets.bottom
    let topInset = swiftUISafeAreaInsets.top
    topBlurView.frame = view.bounds
    topBlurView.frame.size.height = topInset
    bottomBlurView.frame = CGRect(
      x: 0,
      y: view.bounds.height - bottomInset,
      width: view.bounds.width,
      height: bottomInset
    )
  }

  private func applySnapshot() {
    var snapshot = Snapshot()
    snapshot.appendSections([.main])
    snapshot.appendItems(Array(model.messages))

    dataSource.apply(snapshot, animatingDifferences: false) {
      guard !self.model.isPaused else { return }
      self.scrollToBottom(animated: false)
    }
  }

  func update(theme: ThemePalette) {
    self.theme = theme
    setBackgroundColor()
  }

  func update(swiftUISafeAreaInsets: EdgeInsets) {
    self.swiftUISafeAreaInsets = swiftUISafeAreaInsets
    setInsets()
  }

  // MARK: - Setup

  private func configureTableView() {
    tableView.register(MessageCell.self, forCellReuseIdentifier: MessageCell.reuseID)
    tableView.separatorStyle = .none
    tableView.contentInsetAdjustmentBehavior = .never
    tableView.delegate = self
    tableView.rowHeight = UITableView.automaticDimension
    tableView.estimatedRowHeight = 60
    tableView.transform = CGAffineTransform(scaleX: 1, y: -1)
    tableView.topEdgeEffect.isHidden = true
    tableView.bottomEdgeEffect.isHidden = true

    view.addAndFillSubview(tableView)
  }

  private func configureBlur() {
    view.addSubview(topBlurView)

    bottomBlurView.direction = .up
    view.addSubview(bottomBlurView)
  }

  private func makeDataSource() -> DataSource {
    let ds = DataSource(tableView: tableView) { [weak self] tableView, indexPath, item in
      let cell = tableView.dequeueReusableCell(
        withIdentifier: MessageCell.reuseID,
        for: indexPath
      ) as? MessageCell

      guard let cell, let self else { return nil }

      cell.textView.attributedText = model.cachedAttributedString[item.id]
      cell.transform = CGAffineTransform(scaleX: 1, y: -1)

      return cell
    }

    ds.defaultRowAnimation = .none
    return ds
  }

  private func setBackgroundColor() {
    let color = UIColor(theme.bg)
    view.backgroundColor = color
    tableView.backgroundColor = color
  }

  private func setInsets() {
    tableView.contentInset = UIEdgeInsets(
      top: swiftUISafeAreaInsets.bottom,
      left: 0,
      bottom: swiftUISafeAreaInsets.top,
      right: 0
    )
    additionalSafeAreaInsets = .init(
      top: 0,
      left: swiftUISafeAreaInsets.leading,
      bottom: 0,
      right: swiftUISafeAreaInsets.trailing
    )
  }
}

// MARK: - Delegate

extension ChatViewController: UITableViewDelegate {
  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    guard !model.isPaused else { return }
    model.setIsPaused(true)
  }

  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    guard !decelerate else { return }
    executeActionAtTheEnd(of: scrollView)
  }

  func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
    executeActionAtTheEnd(of: scrollView)
  }

  private func scrollToBottom(animated: Bool = false) {
    guard tableView.numberOfRows(inSection: Section.main.rawValue) > 0 else { return }

    let indexPath = IndexPath(row: 0, section: Section.main.rawValue)
    tableView.scrollToRow(at: indexPath, at: .bottom, animated: animated)
  }

  private func executeActionAtTheEnd(of scrollView: UIScrollView) {
    guard scrollView.contentOffset.y < Constants.stickThreshold else { return }
    model.setIsPaused(false)
  }
}

// MARK: - SwiftUI

extension ChatViewController {
  struct SwiftUIView: UIViewControllerRepresentable {
    @Environment(\.theme) private var theme
    @Environment(\.safeAreaInsets) private var safeAreaInsets

    let model: ChatModel

    func makeUIViewController(context: Context) -> ChatViewController {
      .init(
        model: model,
        theme: theme,
        swiftUISafeAreaInsets: safeAreaInsets
      )
    }

    func updateUIViewController(_ uiViewController: ChatViewController, context: Context) {
      uiViewController.update(theme: theme)
      uiViewController.update(swiftUISafeAreaInsets: safeAreaInsets)
    }
  }
}
