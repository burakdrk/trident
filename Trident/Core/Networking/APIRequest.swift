//
//  APIRequest.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-05.
//

import Foundation

struct APIRequest<Response: Decodable> {
    let url: String
    let method: HTTPMethod
    let body: Data?
    let headers: [String: String]
    let decoder: JSONDecoder = .init()
    let token: AuthToken?

    init(
        url: String,
        method: HTTPMethod = .GET,
        body: Data? = nil,
        headers: [String: String] = ["Content-Type": "application/json"],
        token: AuthToken? = nil
    ) {
        self.url = url
        self.method = method
        self.body = body
        self.headers = headers
        self.token = token
    }

    /// convenience initializer for Encodable bodies
    init<Payload: Encodable>(
        url: String,
        method: HTTPMethod = .POST,
        payload: Payload,
        encoder: JSONEncoder = .init(),
        headers: [String: String] = ["Content-Type": "application/json"],
        token: AuthToken? = nil
    ) throws {
        self.url = url
        self.method = method
        self.body = try encoder.encode(payload)
        self.headers = headers
        self.token = token
    }
}

enum HTTPMethod: String {
    case GET, POST, PUT, DELETE
}
