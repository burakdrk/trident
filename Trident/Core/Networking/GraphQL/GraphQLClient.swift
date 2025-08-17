//
//  GraphQLClient.swift
//  Trident
//
//  Created by Burak Duruk on 2025-07-27.
//

import Apollo
import Foundation

actor GraphQLClient {
  private let apollo: ApolloClient

  init() {
    guard let url = URL(string: "https://gql.twitch.tv/gql") else {
      fatalError("Invalid GraphQL URL")
    }
    apollo = ApolloClient(url: url)
  }
}
