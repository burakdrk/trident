//
//  OAuthError.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-20.
//

import Foundation

enum OAuthError: Error {
  case couldNotStart
  case canceled
  case missingToken
  case system(Error)
}
