//
//  Message.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-04.
//

import Foundation
import TwitchIRC

struct Message: Equatable, Identifiable, Sendable {
  let id: String
  let color: String
  let displayName: String
  let emotes: [TwitchIRC.Emote]
  let badges: [String]
  let timestamp: Date
  let body: String

  static func fromPrivateMessage(privateMsg: PrivateMessage) -> Message {
    var color = privateMsg.color
    if privateMsg.color == "#000000" || privateMsg.color.isEmpty {
      color = "#808080"
    }

    return .init(
      id: privateMsg.id,
      color: color,
      displayName: privateMsg.displayName,
      emotes: privateMsg.parseEmotes(),
      badges: privateMsg.badges,
      timestamp: Date(timeIntervalSince1970: Double(privateMsg.tmiSentTs) / 1000),
      body: privateMsg.message
    )
  }

  static func == (lhs: Message, rhs: Message) -> Bool {
    lhs.id == rhs.id
  }
}

struct MessageChunk: Identifiable {
  let id: String
  let type: MessageChunkType
  let text: String // Alt-text if emote
  var emote: Emote?
}

enum MessageChunkType {
  case emote
  case body
  case displayName
  case timestamp
}

struct RenderableMessage: Identifiable, Equatable {
  let id: String
  let details: Message
  let chunks: [MessageChunk]

  init(details: Message, chunks: [MessageChunk]) {
    self.details = details
    self.chunks = chunks
    id = details.id
  }

  static func == (lhs: RenderableMessage, rhs: RenderableMessage) -> Bool {
    lhs.details == rhs.details
  }
}
