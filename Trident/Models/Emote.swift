//
//  Emote.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-05.
//

import Foundation

struct Emote: Identifiable, Equatable {
    let name: String
    let id: String
    let type: EmoteType
    let source: EmoteSource
    var width: Int = 28
    var height: Int = 28

    var url: URL {
        switch source {
        case .BTTV:
            return URL(string: "\(source.rawValue)\(id)/2x.webp")!
        case .FFZ:
            return URL(string: "\(source.rawValue)\(id)/2")!
        case .SevenTV:
            return URL(string: "\(source.rawValue)\(id)/2x.webp")!
        case .Twitch:
            return URL(string: "\(source.rawValue)\(id)/default/dark/2.0")!
        }
    }

    func size(
        fontHeight: CGFloat,
        multiplier: CGFloat = 1.0)
        -> CGSize
    {
        let multiplier = 2.0 * multiplier

        let h = fontHeight
        let ratio = CGFloat(width) / CGFloat(height)
        let w = (h * ratio)
        return CGSize(width: w * multiplier, height: h * multiplier)
    }

    static func == (lhs: Emote, rhs: Emote) -> Bool {
        lhs.id == rhs.id && lhs.source == rhs.source
    }
}

enum EmoteType {
    case Global
    case Channel
    case Personal // Not implemented
    case Unknown
}

enum EmoteSource: String {
    case Twitch = "https://static-cdn.jtvnw.net/emoticons/v2/"
    case BTTV = "https://cdn.betterttv.net/emote/"
    case FFZ = "https://cdn.frankerfacez.com/emote/"
    case SevenTV = "https://cdn.7tv.app/emote/"
}
