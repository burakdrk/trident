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
        let url = URL(string: "https://gql.twitch.tv/gql")!
        apollo = ApolloClient(url: url)
    }
}
