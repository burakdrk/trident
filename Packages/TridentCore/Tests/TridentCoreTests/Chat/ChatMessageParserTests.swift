import DataModels
import Foundation
import Testing
@testable import TridentCore

struct ChatMessageParserTests {
  private static func thirdParty(
    _ name: String,
    overlay: Bool = false,
    source: Emote.Source = .seventv
  ) -> Emote {
    Emote(name: name, sourceID: "\(name)-id", category: .global, source: source, overlay: overlay)
  }

  private func parse(
    _ text: String,
    emotes: [Emote] = [],
    twitchEmotes: String = "",
    color: String = "#0D4200",
    historical: Bool = false
  ) throws -> ChatMessage {
    let raw = privateMessage(in: "forsen", text: text, color: color, emotes: twitchEmotes)
    let parser = ChatMessageParser(
      thirdPartyEmotes: Dictionary(uniqueKeysWithValues: emotes.map { ($0.name, $0) })
    )
    return try parser.parse(pm: parsePrivateMessage(raw), historical: historical)
  }

  // MARK: - Tokenizing

  @Test func plainTextStaysOneRun() throws {
    let message = try parse("hello   there world")

    #expect(message.inlines == [.text("hello there world")])
    #expect(message.rawText == "hello   there world")
  }

  @Test func thirdPartyEmotesAreReplacedByName() throws {
    let kekw = Self.thirdParty("KEKW")

    let message = try parse("hi KEKW there", emotes: [kekw])

    #expect(message.inlines == [
      .text("hi"),
      .text(" "),
      .emote([kekw]),
      .text(" "),
      .text("there")
    ])
  }

  @Test func emoteNamesAreCaseSensitive() throws {
    let message = try parse("kekw", emotes: [Self.thirdParty("KEKW")])

    #expect(message.inlines == [.text("kekw")])
  }

  @Test func twitchEmotesWinOverThirdPartyOnesWithTheSameName() throws {
    let impostor = Self.thirdParty("Kappa")

    let message = try parse("Kappa", emotes: [impostor], twitchEmotes: "25:0-4")

    guard case let .emote(found)? = message.inlines.first else {
      Issue.record("Expected an emote, got \(message.inlines)")
      return
    }
    #expect(found.map(\.source) == [.twitch])
    #expect(found.map(\.sourceID) == ["25"])
  }

  @Test func overlayEmotesStackOnThePreviousEmote() throws {
    let base = Self.thirdParty("catJAM")
    let overlay = Self.thirdParty("RainbowPls", overlay: true)

    let message = try parse("catJAM RainbowPls", emotes: [base, overlay])

    #expect(message.inlines == [.emote([base, overlay])])
  }

  @Test func overlayEmoteWithNothingBeforeItIsJustAnEmote() throws {
    let overlay = Self.thirdParty("RainbowPls", overlay: true)

    let message = try parse("RainbowPls", emotes: [overlay])

    #expect(message.inlines == [.emote([overlay])])
  }

  // MARK: - Metadata

  @Test func carriesTheMessageDetails() throws {
    let message = try parse("hello", historical: true)

    #expect(message.author.displayName == "ronni")
    #expect(message.author.colorHex == "#0D4200")
    #expect(message.historical)
    #expect(message.timestamp == Date(timeIntervalSince1970: 1_507_246_572.675))
  }

  @Test(arguments: ["", "#000000"])
  func unreadableNameColorsFallBackToGray(color: String) throws {
    let message = try parse("hello", color: color)

    #expect(message.author.colorHex == "#808080")
  }
}
