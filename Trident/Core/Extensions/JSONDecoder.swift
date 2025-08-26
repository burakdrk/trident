//
//  JSONDecoder.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-25.
//

import Foundation

extension JSONDecoder {
  static let shared: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .millisecondsSince1970
    return decoder
  }()
}
