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
    let emotes: [Emote]
    let badges: [String]
    let timestamp: Date
    let body: String

    static func fromPrivateMessage(pm: PrivateMessage) -> Message {
        .init(
            id: pm.id,
            color: pm.color,
            displayName: pm.displayName,
            emotes: [],
            badges: pm.badges,
            timestamp: Date(timeIntervalSince1970: Double(pm.tmiSentTs) / 1000),
            body: pm.message
        )
    }

    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id
    }
}
