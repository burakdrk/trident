//
//  ThirdPartyEmoteClient.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-04.
//

import Collections
import Foundation

actor ThirdPartyEmoteClient {
  private let services: [any ThirdPartyEmoteService]
  private var emotes: [String: Emote]?
  private var forChannelID: String?

  /// Creates an instance of the emote aggregator. Servoce order matters.
  init(services: [any ThirdPartyEmoteService]) {
    self.services = services
  }

  /// Retrieves a dictionary of unique emotes from all configured services, keyed by emote name.
  func emotes(for channelID: String) async -> [String: Emote] {
    // If emotes are already fetched, return them.
    if let cachedEmotes = emotes, forChannelID == channelID {
      return cachedEmotes
    }

    async let globalEmotes = fetchOrderedEmotes(from: { try await $0.globalEmotes() })
    async let channelEmotes =
      fetchOrderedEmotes(from: { try await $0.channelEmotes(for: channelID) })

    let (allGlobal, allChannel) = await (globalEmotes, channelEmotes)

    var uniqueEmotes = Dictionary(
      allGlobal.map { ($0.name, $0) },
      uniquingKeysWith: { _, new in new }
    )

    uniqueEmotes.merge(allChannel.map { ($0.name, $0) }, uniquingKeysWith: { _, new in new })

    emotes = uniqueEmotes
    forChannelID = channelID

    return uniqueEmotes
  }

  private func fetchOrderedEmotes(
    from fetcher: @Sendable @escaping (any ThirdPartyEmoteService) async throws -> [Emote]
  ) async -> [Emote] {
    await withTaskGroup(of: (Int, [Emote]).self, returning: [Emote].self) { group in
      for (index, service) in self.services.enumerated() {
        group.addTask {
          do {
            let emotes = try await fetcher(service)
            return (index, emotes)
          } catch {
            #if DEBUG
              print(
                "Warning: Service \(index) failed to fetch emotes: \(error.localizedDescription)"
              )
            #endif
            return (index, [])
          }
        }
      }

      var indexedResults: [(Int, [Emote])] = []
      for await result in group {
        indexedResults.append(result)
      }

      return indexedResults.sorted { $0.0 < $1.0 }.flatMap { $0.1 }
    }
  }
}
