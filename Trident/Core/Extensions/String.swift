//
//  String.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-12.
//

extension String {
  static func randomAlphanumeric(length: Int) -> String {
    let charset = Array("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
    return String(
      (0 ..< length).compactMap { _ in charset.randomElement() }
    )
  }
}
