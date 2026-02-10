import UIKit

private enum Constants {
  static let verticalInset: CGFloat = 4
  static let horizontalInset: CGFloat = 5
}

final class MessageCell: UITableViewCell {
  static let reuseID = "MessageCellId"

  lazy var textView: UITextView = LinkOnlyTextView()

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)

    // Configure the cell
    selectionStyle = .none
    backgroundColor = .clear

    setupTextView() // Setup the text view with necessary properties
  }

  @available(*, unavailable)
  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Configuration

  private func setupTextView() {
    textView.translatesAutoresizingMaskIntoConstraints = false
    textView.isEditable = false
    textView.isSelectable = true
    textView.dataDetectorTypes = [.link]
    textView.isScrollEnabled = false
    textView.backgroundColor = .clear
    textView.textContainerInset = UIEdgeInsets(
      top: Constants.verticalInset,
      left: Constants.horizontalInset,
      bottom: Constants.verticalInset,
      right: Constants.horizontalInset
    )
    textView.textContainer.lineFragmentPadding = .zero

    contentView.addSubview(textView)

    NSLayoutConstraint.activate([
      textView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 0),
      textView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 0),
      textView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: 0),
      textView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: 0)
    ])
  }
}
