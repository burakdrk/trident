import DataModels
import Foundation
import Testing
@testable import TridentCore

struct RecentMessagesServiceTests {
  // Lines in the shape recent-messages.robotty.de returns them: bare `flags;`/`badge-info;` tags
  // without a value.
  private static let withEmotesTag =
    "@flags;color=#FF4500;emotes;historical=1;subscriber=0;tmi-sent-ts=1791613777812;"
      + "badge-info;display-name=Alice;room-id=1;first-msg=0;id=first;badges=;turbo=0;mod=0;"
      + "user-type;user-id=2;rm-received-ts=1791613778228 "
      + ":alice!alice@alice.tmi.twitch.tv PRIVMSG #forsen :!hello world"

  private static let secondMessage =
    "@flags;color=#00C5FF;emotes;historical=1;tmi-sent-ts=1791613946450;badge-info;"
      + "display-name=Bob;room-id=1;id=second;badges=;user-type;user-id=3 "
      + ":bob!bob@bob.tmi.twitch.tv PRIVMSG #forsen :later message"

  // Emote-only messages come without the ":" in front of the text.
  private static let withoutColon =
    "@flags;color=#00C5FF;emotes=emotesv2_332a69bd22374abf97da64b07b650dd1:0-8;historical=1;"
      + "tmi-sent-ts=1791613946450;badge-info;display-name=Carol;room-id=1;id=emoteonly;badges=;"
      + "emote-only=1;user-type;user-id=4 :carol!carol@carol.tmi.twitch.tv PRIVMSG #forsen Happie"

  private static let clearChat = "@room-id=1;target-user-id=3;tmi-sent-ts=1791613946000 "
    + ":tmi.twitch.tv CLEARCHAT #forsen :bob"

  @Test func keepsTheOrderTheServiceSentThemIn() {
    let messages = RecentMessagesService.parse(
      lines: [Self.withEmotesTag, Self.secondMessage],
      emotes: [:]
    )

    #expect(messages.map(\.id) == ["first", "second"])
  }

  @Test func marksEverythingAsHistorical() {
    let messages = RecentMessagesService.parse(lines: [Self.withEmotesTag], emotes: [:])

    #expect(messages.map(\.historical) == [true])
  }

  @Test func ignoresLinesThatAreNotChatMessages() {
    let messages = RecentMessagesService.parse(
      lines: [Self.clearChat, Self.withEmotesTag, "garbage"],
      emotes: [:]
    )

    #expect(messages.map(\.id) == ["first"])
  }

  @Test func keepsEmoteOnlyMessages() {
    let messages = RecentMessagesService.parse(lines: [Self.withoutColon], emotes: [:])

    #expect(messages.map(\.id) == ["emoteonly"])
  }

  @Test func resolvesThirdPartyEmotes() {
    let emote = Emote(
      name: "world",
      sourceID: "1",
      category: .global,
      source: .bttv,
      overlay: false
    )

    let messages = RecentMessagesService.parse(
      lines: [Self.withEmotesTag],
      emotes: ["world": emote]
    )

    #expect(messages.first?.inlines.contains(.emote([emote])) == true)
  }
}
