import Collections
import DataModels
import Foundation

actor MessageBuffer {
  private var buffer: [ChatMessage] = []
  private var pauseBuffer: Deque<ChatMessage> = []

  private let pauseMax: Int

  var pendingMessages: Int {
    buffer.count + pauseBuffer.count
  }

  init(pauseMax: Int) {
    self.pauseMax = pauseMax
  }

  func add(_ msg: ChatMessage, paused: Bool = false) {
    if paused {
      while pauseBuffer.count >= pauseMax {
        _ = pauseBuffer.popFirst()
      }
      pauseBuffer.append(msg)
    } else {
      buffer.append(msg)
    }
  }

  func addRecents(_ msgs: [ChatMessage]) {
    buffer.append(contentsOf: msgs)
  }

  func flush() -> [ChatMessage] {
    let batch = buffer + pauseBuffer
    buffer.removeAll()
    pauseBuffer.removeAll()
    return batch
  }
}
