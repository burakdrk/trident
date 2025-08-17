//
//  MessageBuffer.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-04.
//

import Collections
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

  func flush() -> [ChatMessage] {
    let batch = buffer.drain()
    let pauseBatch = pauseBuffer.drain()

    return pauseBatch + batch
  }
}
