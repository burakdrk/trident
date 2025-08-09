//
//  BTTVService.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-05.
//

import Foundation

/// A service that fetches emotes from the BetterTTV (BTTV) API.
struct BTTVService: ThirdPartyEmoteService {
    private let baseAPIURL = "https://api.betterttv.net/3"
    private let baseCDNURL = "https://cdn.betterttv.net/emote"
    private let requestTimeout: TimeInterval = 5.0

    func channelEmotes(for channelID: String) async throws -> [Emote] {
        let urlString = "\(baseAPIURL)/cached/users/twitch/\(channelID)"
        let response: BTTVChannelEmoteResponse = try await URLSession.perform(.init(url: urlString, timeoutInterval: requestTimeout))

        // Use a dictionary to merge emotes. This ensures channel emotes overwrite
        // shared emotes if they have the same name, matching the original logic.
        var uniqueEmotes = [String: BTTVEmote]()
        response.sharedEmotes.forEach { uniqueEmotes[$0.code] = $0 }
        response.channelEmotes.forEach { uniqueEmotes[$0.code] = $0 }

        return uniqueEmotes.values.compactMap { mapToEmote($0, .Channel) }
    }

    func globalEmotes() async throws -> [Emote] {
        let urlString = "\(baseAPIURL)/cached/emotes/global"
        let bttvEmotes: [BTTVEmote] = try await URLSession.perform(.init(url: urlString, timeoutInterval: requestTimeout))

        return bttvEmotes.compactMap { mapToEmote($0, .Global) }
    }

    // MARK: - Private Helpers

    private func mapToEmote(_ bttvEmote: BTTVEmote, _ type: EmoteType) -> Emote? {
        Emote(name: bttvEmote.code, id: bttvEmote.id, type: type, source: .BTTV, width: bttvEmote.width ?? 28, height: bttvEmote.height ?? 28)
    }
}

// MARK: - BTTV-Specific Models

private struct BTTVEmote: Decodable {
    let id: String
    let code: String // This is the emote's unique name
    let width: Int?
    let height: Int?
}

private struct BTTVChannelEmoteResponse: Decodable {
    let channelEmotes: [BTTVEmote]
    let sharedEmotes: [BTTVEmote]
}
