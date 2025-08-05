//
//  ThirdPartyEmoteClient.swift
//  Trident
//
//  Created by Burak Duruk on 2025-08-04.
//

import Collections
import Foundation

actor ThirdPartyEmoteClient {
    private let channelID: String
    private let services: [any ThirdPartyEmoteService]

    /// Creates an instance of the emote aggregator
    /// - Parameters:
    ///   - channelID: The ID of the channel for which to fetch emote
    ///   - services: An array of emote services. **Order matters**: Emotes from services
    ///     later in the array will overwrite those from earlier services.
    init(channelID: String, services: [any ThirdPartyEmoteService]) {
        self.channelID = channelID
        self.services = services
    }

    /// Retrieves a dictionary of unique emotes from all configured services, keyed by emote name.
    ///
    /// 1.  Channel emotes overwrite global emotes.
    /// 2.  Emotes from services that appear later in the `services` array overwrite those from earlier services.
    ///
    /// - Returns: A dictionary mapping unique emote names to their corresponding `Emote` objects.
    func emotes() async -> [String: Emote] {
        async let globalEmotes = fetchOrderedEmotes(from: { try await $0.globalEmotes() })
        async let channelEmotes = fetchOrderedEmotes(from: { try await $0.channelEmotes(for: self.channelID) })

        let (allGlobal, allChannel) = await (globalEmotes, channelEmotes)

        var uniqueEmotes = Dictionary(allGlobal.map { ($0.name, $0) }, uniquingKeysWith: { _, new in new })

        uniqueEmotes.merge(allChannel.map { ($0.name, $0) }, uniquingKeysWith: { _, new in new })

        return uniqueEmotes
    }

    /// A private helper function to fetch emotes from all services in parallel while preserving order.
    /// - Parameter fetcher: An async closure that takes a service and returns its emotes.
    /// - Returns: A flattened array of emotes, in the order of the original `services` array.
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
                        print("Warning: A service failed to fetch emotes: \(error.localizedDescription)")
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
