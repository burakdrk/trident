import DataModels
import Testing
@testable import Trident

struct MessageBufferTests {
  private func message(_ id: String) -> ChatMessage {
    ChatMessage(
      id: id,
      inlines: [],
      author: .init(displayName: "a", colorHex: "#FFFFFF", badges: []),
      timestamp: .now,
      rawText: id,
      historical: false
    )
  }

  @Test func flushReturnsEverythingOnceInOrder() async {
    let buffer = MessageBuffer(pauseMax: 10)

    await buffer.addRecents([message("r1"), message("r2")])
    await buffer.add(message("l1"))
    await buffer.add(message("l2"))

    #expect(await buffer.pendingMessages == 4)
    #expect(await buffer.flush().map(\.id) == ["r1", "r2", "l1", "l2"])
    #expect(await buffer.flush().isEmpty)
    #expect(await buffer.pendingMessages == 0)
  }

  @Test func messagesArrivingWhilePausedComeAfterTheOnesBeforeThePause() async {
    let buffer = MessageBuffer(pauseMax: 10)

    await buffer.add(message("before"))
    await buffer.add(message("paused1"), paused: true)
    await buffer.add(message("paused2"), paused: true)

    #expect(await buffer.flush().map(\.id) == ["before", "paused1", "paused2"])
  }

  @Test func pausedMessagesKeepOnlyTheNewestOnes() async {
    let buffer = MessageBuffer(pauseMax: 3)

    for index in 1...5 {
      await buffer.add(message("m\(index)"), paused: true)
    }

    #expect(await buffer.pendingMessages == 3)
    #expect(await buffer.flush().map(\.id) == ["m3", "m4", "m5"])
  }
}
