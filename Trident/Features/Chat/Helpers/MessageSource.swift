import Collections
import DataModels
import UIKit

struct MessageSource: Equatable {
  private var messages: Deque<ChatMessage> = []
  private(set) var snapshot: NSDiffableDataSourceSnapshot<Int, ChatMessage>
  var capacity: Int
  var updateID = UUID()

  // ID -> Height
  var cachedHeight: [String: CGFloat] = [:]
  // ID -> Attributed String
  var cachedAttributedString: [String: NSAttributedString] = [:]

  init(capacity: Int) {
    var snapshot = NSDiffableDataSourceSnapshot<Int, ChatMessage>()
    snapshot.appendSections([0])
    snapshot.appendItems([], toSection: 0)
    self.snapshot = snapshot
    self.capacity = capacity
  }

  mutating func add(_ newMessages: [ChatMessage], fittingWidth: CGFloat?) {
    defer { updateID = UUID() }

    for newMessage in newMessages {
      messages.append(newMessage)
      snapshot.appendItems([newMessage], toSection: 0)

      let attrString = MessageProcessor.makeAttributedString(
        for: newMessage,
        font: UIFont.systemFont(ofSize: 16)
      )
      cachedAttributedString[newMessage.id] = attrString

      guard let fittingWidth else { continue }
      let height = MessageProcessor.calculateHeight(for: attrString, fittingWidth: fittingWidth)
      cachedHeight[newMessage.id] = height
    }

    // Compute deletes if overflow
    if messages.count > capacity {
      let overflow = messages.count - capacity

      for _ in 1...overflow {
        if let deletedMessage = messages.popFirst() {
          snapshot.deleteItems([deletedMessage])
          cachedHeight.removeValue(forKey: deletedMessage.id)
          cachedAttributedString.removeValue(forKey: deletedMessage.id)
        }
      }
    }
  }

  static func == (lhs: MessageSource, rhs: MessageSource) -> Bool {
    lhs.updateID == rhs.updateID
  }
}
