//
//  APIError.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-05.
//

import Foundation

enum APIError: Error {
    case invalidResponse
    case statusCode(Int, message: String)
    case decoding(Error)
    case unknown(Error)
}
