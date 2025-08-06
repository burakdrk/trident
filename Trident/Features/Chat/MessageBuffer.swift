//
//  MessageBuffer.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-04.
//

import Collections
import Foundation

actor MessageBuffer {
    private var buffer: [Message] = []
    private var pauseBuffer: Deque<Message> = []
    private var messages: [Message] = []

    private let max: Int
    private let pauseMax: Int

    var pendingMessages: Int {
        buffer.count + pauseBuffer.count
    }

    init(max: Int = 1500, pauseMax: Int = 1500) {
        self.max = max
        self.pauseMax = pauseMax
    }

    func add(_ msg: Message, paused: Bool = false) {
        if paused {
            while pauseBuffer.count >= pauseMax {
                _ = pauseBuffer.popFirst()
            }
            pauseBuffer.append(msg)
        } else {
            buffer.append(msg)
        }
    }

    var renderList: [Message] {
        let batch = buffer.drain()
        let pauseBatch = pauseBuffer.drain()

        messages.append(contentsOf: pauseBatch)
        messages.append(contentsOf: batch)
        if messages.count > max {
            messages.removeFirst(messages.count - max)
        }

        return messages
    }
}
