//
//  IRCError.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-04.
//

import Foundation

enum IRCError: LocalizedError {
    case failedToConnect

    var errorDescription: String? {
        switch self {
        case .failedToConnect:
            return "Failed to connect to the chat"
        }
    }
}
