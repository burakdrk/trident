//
//  JSONEncoder.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-25.
//

import Foundation

extension JSONEncoder {
  static let shared: JSONEncoder = {
    let encoder = JSONEncoder()
    encoder.keyEncodingStrategy = .convertToSnakeCase
    encoder.dateEncodingStrategy = .millisecondsSince1970
    return encoder
  }()
}
