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
