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

    static func fromPrivateMessage(pm: PrivateMessage) -> Message {
        var color = pm.color
        if pm.color == "#000000" || pm.color.isEmpty {
            color = "#808080"
        }

        return .init(
            id: pm.id,
            color: color,
            displayName: pm.displayName,
            emotes: pm.parseEmotes(),
            badges: pm.badges,
            timestamp: Date(timeIntervalSince1970: Double(pm.tmiSentTs) / 1000),
            body: pm.message
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
        self.id = details.id
    }

    static func == (lhs: RenderableMessage, rhs: RenderableMessage) -> Bool {
        lhs.details == rhs.details
    }
}
