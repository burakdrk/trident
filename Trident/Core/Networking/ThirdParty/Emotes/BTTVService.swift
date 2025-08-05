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
        let response: BTTVChannelEmoteResponse = try await URLSession.perform(.init(url: urlString))

        // Use a dictionary to merge emotes. This ensures channel emotes overwrite
        // shared emotes if they have the same name, matching the original logic.
        var uniqueEmotes = [String: BTTVEmote]()
        response.sharedEmotes.forEach { uniqueEmotes[$0.code] = $0 }
        response.channelEmotes.forEach { uniqueEmotes[$0.code] = $0 }

        return uniqueEmotes.values.compactMap { mapToEmote($0) }
    }

    func globalEmotes() async throws -> [Emote] {
        let urlString = "\(baseAPIURL)/cached/emotes/global"
        let bttvEmotes: [BTTVEmote] = try await URLSession.perform(.init(url: urlString))

        return bttvEmotes.compactMap { mapToEmote($0) }
    }

    // MARK: - Private Helpers

    private func mapToEmote(_ bttvEmote: BTTVEmote) -> Emote? {
        guard let emoteURL = URL(string: "\(baseCDNURL)/\(bttvEmote.id)/1x") else {
            return nil
        }

        return Emote(name: bttvEmote.code, url: emoteURL, type: .BTTV)
    }
}

// MARK: - BTTV-Specific Models

private struct BTTVEmote: Decodable {
    let id: String
    let code: String // This is the emote's name
}

private struct BTTVChannelEmoteResponse: Decodable {
    let channelEmotes: [BTTVEmote]
    let sharedEmotes: [BTTVEmote]
}
