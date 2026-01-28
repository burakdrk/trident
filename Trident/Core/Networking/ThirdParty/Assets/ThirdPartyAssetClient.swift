import Collections
import DataModels
import Foundation

actor ThirdPartyAssetClient {
  private let services: [any ThirdPartyAssetService]

  /// Registry that maps channel IDs to a list of emotes.
  private let channelEmoteCache = Cache<String, [Emote]>()
  private var globalEmoteCache: [Emote]?

  /// Service order matters for precedence in case of emote name collisions.
  init(services: [any ThirdPartyAssetService]) {
    self.services = services
  }

  /// Retrieves a dictionary of unique emotes from all configured services, keyed by emote name.
  func emotes(for channelID: String?) async -> [String: Emote] {
    async let g = getGlobalEmotes()
    async let c = getChannelEmotes(for: channelID)
    let (allGlobal, allChannel) = await (g, c)

    var uniqueEmotes = Dictionary(
      allGlobal.map { ($0.name, $0) },
      uniquingKeysWith: { _, new in new }
    )

    // Channel emotes take precedence over global emotes in case of name collisions.
    uniqueEmotes.merge(allChannel.map { ($0.name, $0) }, uniquingKeysWith: { _, new in new })

    return uniqueEmotes
  }
}

// MARK: - Emote Helpers

private extension ThirdPartyAssetClient {
  func getGlobalEmotes() async -> [Emote] {
    if let cache = globalEmoteCache {
      return cache
    }

    let tmp = await fetchOrderedEmotes(from: { try await $0.globalEmotes() })
    globalEmoteCache = tmp
    return tmp
  }

  func getChannelEmotes(for channelID: String?) async -> [Emote] {
    guard let channelID else { return [] }

    if let cache = channelEmoteCache[channelID] {
      return cache
    }

    let tmp = await fetchOrderedEmotes(from: { try await $0.channelEmotes(for: channelID) })
    channelEmoteCache[channelID] = tmp
    return tmp
  }

  func fetchOrderedEmotes(
    from fetcher: @Sendable @escaping (any ThirdPartyAssetService) async throws -> [Emote]
  ) async -> [Emote] {
    await withTaskGroup(of: (Int, [Emote]).self, returning: [Emote].self) { group in
      for (index, service) in self.services.enumerated() {
        group.addTask {
          do {
            let emotes = try await fetcher(service)
            return (index, emotes)
          } catch {
            TridentLog.main
              .warning("Service \(index) failed to fetch emotes: \(error.localizedDescription)")
            return (index, [])
          }
        }
      }

      var indexedResults: [(Int, [Emote])] = []
      for await result in group {
        indexedResults.append(result)
      }

      return indexedResults.sorted { $0.0 < $1.0 }.flatMap(\.1)
    }
  }
}
