import DataModels
import Dependencies
import Foundation
import Testing
@testable import TridentCore

/// A service that returns fixed emotes and counts how often it was asked.
private final class FakeService: ThirdPartyAssetService {
  let globals: [Emote]
  let channels: [String: [Emote]]
  let fails: Bool
  let globalCalls = LockIsolated(0)
  let channelCalls = LockIsolated(0)

  init(globals: [Emote] = [], channels: [String: [Emote]] = [:], fails: Bool = false) {
    self.globals = globals
    self.channels = channels
    self.fails = fails
  }

  func globalEmotes() async throws -> [Emote] {
    globalCalls.withValue { $0 += 1 }
    if fails { throw URLError(.notConnectedToInternet) }
    return globals
  }

  func channelEmotes(for channelID: String) async throws -> [Emote] {
    channelCalls.withValue { $0 += 1 }
    if fails { throw URLError(.notConnectedToInternet) }
    return channels[channelID] ?? []
  }
}

@Suite(.timeLimit(.minutes(1)))
struct ThirdPartyAssetClientTests {
  private static func emote(
    _ name: String,
    _ source: Emote.Source,
    _ category: Emote.Category = .global
  ) -> Emote {
    Emote(
      name: name,
      sourceID: "\(name)-\(source.rawValue)",
      category: category,
      source: source,
      overlay: false
    )
  }

  @Test func combinesEmotesFromEveryServiceByName() async {
    let client = ThirdPartyAssetClient(services: [
      FakeService(globals: [Self.emote("A", .ffz)]),
      FakeService(globals: [Self.emote("B", .bttv)])
    ])

    let emotes = await client.emotes(for: nil)

    #expect(Set(emotes.keys) == ["A", "B"])
    #expect(emotes["A"]?.source == .ffz)
  }

  @Test func laterServicesWinWhenTwoShareAName() async {
    let client = ThirdPartyAssetClient(services: [
      FakeService(globals: [Self.emote("Same", .ffz)]),
      FakeService(globals: [Self.emote("Same", .bttv)]),
      FakeService(globals: [Self.emote("Same", .seventv)])
    ])

    let emotes = await client.emotes(for: nil)

    #expect(emotes["Same"]?.source == .seventv)
  }

  @Test func channelEmotesBeatGlobalOnesWithTheSameName() async {
    let client = ThirdPartyAssetClient(services: [
      FakeService(
        globals: [Self.emote("Same", .seventv, .global)],
        channels: ["1": [Self.emote("Same", .ffz, .channel)]]
      )
    ])

    let emotes = await client.emotes(for: "1")

    #expect(emotes["Same"]?.category == .channel)
    #expect(emotes["Same"]?.source == .ffz)
  }

  @Test func withoutAChannelOnlyGlobalEmotesComeBack() async {
    let service = FakeService(
      globals: [Self.emote("G", .ffz)],
      channels: ["1": [Self.emote("C", .ffz, .channel)]]
    )
    let client = ThirdPartyAssetClient(services: [service])

    let emotes = await client.emotes(for: nil)

    #expect(Set(emotes.keys) == ["G"])
    #expect(service.channelCalls.value == 0)
  }

  @Test func aServiceThatFailsDoesNotTakeTheOthersDown() async {
    let client = ThirdPartyAssetClient(services: [
      FakeService(fails: true),
      FakeService(globals: [Self.emote("B", .bttv)])
    ])

    let emotes = await client.emotes(for: nil)

    #expect(Set(emotes.keys) == ["B"])
  }

  @Test func globalAndChannelEmotesAreOnlyFetchedOnce() async {
    let service = FakeService(
      globals: [Self.emote("G", .ffz)],
      channels: ["1": [Self.emote("C", .ffz, .channel)]]
    )
    let client = ThirdPartyAssetClient(services: [service])

    _ = await client.emotes(for: "1")
    _ = await client.emotes(for: "1")
    _ = await client.emotes(for: "2")

    #expect(service.globalCalls.value == 1)
    #expect(service.channelCalls.value == 2) // "1" once, "2" once
  }
}
