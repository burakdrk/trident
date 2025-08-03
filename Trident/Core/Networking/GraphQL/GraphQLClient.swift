//
//  GraphQLClient.swift
//  Trident
//
//  Created by Burak Duruk on 2025-07-27.
//

import Foundation
import Apollo

class GraphQLClient {
    private let apollo: ApolloClient
    
    init() {
        let url = URL(string: "https://gql.twitch.tv/gql")!
        self.apollo = ApolloClient(url: url)
    }
}
