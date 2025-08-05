//
//  Emote.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-05.
//

import Foundation

struct Emote {
    let name: String
    let url: URL
    let type: EmoteType
}

enum EmoteType {
    case Twitch
    case BTTV
    case FFZ
    case SevenTV
}
