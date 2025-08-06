//
//  URLSession+perform.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-05.
//

import Foundation

extension URLSession {
    static func perform<T: Decodable>(_ req: APIRequest<T>) async throws -> T {
        guard let url = URL(string: req.url) else {
            throw URLError(.badURL)
        }

        var urlReq = URLRequest(url: url, timeoutInterval: req.timeoutInterval)
        urlReq.httpMethod = req.method.rawValue
        req.headers.forEach { urlReq.setValue($1, forHTTPHeaderField: $0) }
        urlReq.httpBody = req.body

        if let token = req.token {
            urlReq.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await self.shared.data(for: urlReq)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        guard 200 ... 299 ~= http.statusCode else {
            let msg = HTTPURLResponse.localizedString(forStatusCode: http.statusCode)
            throw APIError.statusCode(http.statusCode, message: msg)
        }

        do {
            return try req.decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decoding(error)
        }
    }
}
