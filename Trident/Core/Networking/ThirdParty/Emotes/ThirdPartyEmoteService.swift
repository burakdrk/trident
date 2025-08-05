//
//  ThirdPartyEmoteService.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-04.
//

protocol ThirdPartyEmoteService: Sendable {
    func channelEmotes(for channelID: String) async throws -> [Emote]
    func globalEmotes() async throws -> [Emote]
}
