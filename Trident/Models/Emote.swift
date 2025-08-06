//
//  Emote.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-05.
//

import Foundation

struct Emote: Identifiable {
    let name: String
    let id: String
    let type: EmoteType
    let source: EmoteSource
    var width: Int?
    var height: Int?

    var url: URL? {
        switch source {
        case .BTTV:
            return URL(string: "\(source.rawValue)\(id)/1x.webp")
        case .FFZ:
            return URL(string: "\(source.rawValue)\(id)/1.webp")
        case .SevenTV:
            return URL(string: "\(source.rawValue)\(id)/1x.webp")
        case .Twitch:
            return URL(string: "\(source.rawValue)\(id)/default/dark/1.0")
        }
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
