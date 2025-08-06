//
//  MessageParser.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-05.
//

import Foundation

actor MessageParser {
    private let messages: [Message]
    private let thirdPartyEmotes: [String: Emote]

    init(messages: [Message], thirdPartyEmotes: [String: Emote]) {
        self.messages = messages
        self.thirdPartyEmotes = thirdPartyEmotes
    }

    var renderStream: [RenderableMessage] {
        messages.map {
            RenderableMessage(
                details: $0,
                chunks: chunks(message: $0)
            )
        }
    }

    private func chunks(message: Message) -> [MessageChunk] {
        var uniqueTwitchEmotes: [String: Emote] = [:]
        for item in message.emotes.unique(by: \.id) {
            uniqueTwitchEmotes[item.name] = Emote(name: item.name,
                                                  id: item.id,
                                                  type: .Unknown,
                                                  source: .Twitch)
        }

        var chunks: [MessageChunk] = []

        chunks.append(
            MessageChunk(
                id: message.id + "_displayName",
                type: .displayName,
                text: message.displayName
            )
        )

        chunks.append(contentsOf: message.body
            .split(whereSeparator: { $0.isWhitespace }) // splits on any run of whitespace
            .map(String.init)
            .enumerated()
            .map { index, part in
                let emote = uniqueTwitchEmotes[part] ?? thirdPartyEmotes[part]

                if let emote = emote {
                    return MessageChunk(
                        id: message.id + "_" + String(index),
                        type: .emote,
                        text: part,
                        emote: emote
                    )
                }

                return MessageChunk(
                    id: message.id + "_" + String(index),
                    type: .body,
                    text: part
                )
            })

        return chunks
    }
}
