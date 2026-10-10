import DataModels
import Dependencies
import Foundation
import Testing
@testable import TridentCore
import TwitchIRC

@Suite(.timeLimit(.minutes(1)))
struct IRCClientTests {
  private let harness = IRCHarness()

  private func connectedClient() async -> (IRCClient, EventRecorder) {
    let client = harness.makeClient()
    let recorder = await EventRecorder(client.subscribe(to: nil))
    await client.connect()
    return (client, recorder)
  }

  // MARK: - Connecting

  @Test func logsInWithCapabilitiesThenCredentials() async {
    let (client, recorder) = await connectedClient()
    defer { Task { await client.disconnect() } }

    #expect(harness.sockets.count == 1)
    #expect(
      harness.sockets.value[0].sent.value == [
        "CAP REQ :twitch.tv/tags twitch.tv/commands",
        "PASS oauth:SCHMOOPIIE",
        "NICK justinfan28264"
      ]
    )

    harness.sockets.value[0].push(FakeSocket.welcome)
    await waitUntil("authenticated") { recorder.statuses.last == .authenticated }

    #expect(recorder.statuses == [.disconnected, .connecting, .connected, .authenticated])
  }

  @Test func callingConnectTwiceOpensOneSocket() async {
    let client = harness.makeClient()
    defer { Task { await client.disconnect() } }

    async let first: Void = client.connect()
    async let second: Void = client.connect()
    _ = await (first, second)
    await client.connect()

    #expect(harness.sockets.count == 1)
  }

  @Test func newSubscribersGetTheCurrentStatusFirst() async {
    let (client, _) = await connectedClient()
    defer { Task { await client.disconnect() } }

    let late = await EventRecorder(client.subscribe(to: nil))

    await waitUntil("status") { !late.statuses.isEmpty }
    #expect(late.statuses == [.connected])
  }

  @Test func handshakeThatNeverAnswersTimesOutAndRetries() async {
    harness.socketForAttempt.setValue { _ in FakeSocket(acknowledgesCapabilities: false) }
    let client = harness.makeClient()
    let recorder = await EventRecorder(client.subscribe(to: nil))
    defer { Task { await client.disconnect() } }

    let connecting = Task { await client.connect() }
    await waitUntil("first socket") { harness.sockets.count == 1 }

    await harness
      .advance(until: { recorder.statuses.contains(.failed(IRCError.timedOut.errorDescription)) })
    await connecting.value

    #expect(recorder.statuses.contains(.failed(IRCError.timedOut.errorDescription)))
    #expect(harness.sockets.value[0].isClosed.value)

    // And it keeps trying.
    await harness.advance(until: { harness.sockets.count == 2 })
    #expect(harness.sockets.count == 2)
  }

  // MARK: - Reconnecting

  @Test func reconnectsAfterTheConnectionDropsAndRejoinsChannels() async {
    let (client, recorder) = await connectedClient()
    defer { Task { await client.disconnect() } }

    try? await client.join(to: .sample("forsen"))
    try? await client.join(to: .sample("xqc"))
    harness.sockets.value[0].drop()

    await waitUntil("failure") {
      recorder.statuses.contains { if case .failed = $0 { true } else { false } }
    }
    await harness.advance(until: { harness.sockets.count == 2 })
    await waitUntil("rejoin") {
      harness.sockets.value.count == 2 && harness.sockets.value[1].sent.value.count >= 5
    }

    let second = harness.sockets.value[1].sent.value
    #expect(second.suffix(2) == ["JOIN #forsen", "JOIN #xqc"])
    #expect(Array(recorder.statuses.suffix(2)) == [.connecting, .connected])
  }

  @Test func backsOffBetweenFailedAttempts() async {
    harness.socketForAttempt.setValue { _ in FakeSocket(failsOnSend: true) }
    let client = harness.makeClient()
    defer { Task { await client.disconnect() } }

    await client.connect() // attempt 1 fails right away
    #expect(harness.sockets.count == 1)

    // Backoff is 1s, then 2s, then 4s. Stepping tells us how long each wait really was.
    let first = await harness.advance(until: { harness.sockets.count == 2 })
    let second = await harness.advance(until: { harness.sockets.count == 3 })
    let third = await harness.advance(until: { harness.sockets.count == 4 })

    #expect(first >= .seconds(1) && first <= .seconds(1.5))
    #expect(second >= .seconds(2) && second <= .seconds(2.5))
    #expect(third >= .seconds(4) && third <= .seconds(4.5))
  }

  @Test func backoffGrowsAndIsCapped() {
    let delays = (0..<8).map { IRCClient.backoff(forAttempt: $0) }
    #expect(delays == [1, 2, 4, 8, 16, 30, 30, 30].map { Duration.seconds($0) })
  }

  @Test func reconnectsWhenTwitchAsksTo() async {
    let (client, recorder) = await connectedClient()
    defer { Task { await client.disconnect() } }

    harness.sockets.value[0].push(FakeSocket.reconnect)

    await waitUntil("failure") {
      recorder.statuses.contains(.failed(IRCError.serverRequestedReconnect.errorDescription))
    }
    await harness.advance(until: { harness.sockets.count == 2 })

    #expect(harness.sockets.count == 2)
  }

  // MARK: - Disconnecting

  @Test func disconnectingOnPurposeDoesNotReconnectOrReportAFailure() async {
    let (client, recorder) = await connectedClient()

    await client.disconnect()
    await harness.advance(by: .seconds(120))

    #expect(harness.sockets.count == 1)
    #expect(harness.sockets.value[0].isClosed.value)
    #expect(recorder.statuses.last == .disconnected)
    #expect(!recorder.statuses.contains { if case .failed = $0 { true } else { false } })
  }

  @Test func disconnectingWhileWaitingToReconnectCancelsTheRetry() async {
    let (client, recorder) = await connectedClient()

    harness.sockets.value[0].drop()
    await waitUntil("failure") {
      recorder.statuses.contains { if case .failed = $0 { true } else { false } }
    }

    await client.disconnect()
    await harness.advance(by: .seconds(120))

    #expect(harness.sockets.count == 1)
    #expect(recorder.statuses.last == .disconnected)
  }

  @Test func canConnectAgainAfterDisconnecting() async {
    let (client, _) = await connectedClient()
    defer { Task { await client.disconnect() } }

    await client.disconnect()
    await client.connect()

    #expect(harness.sockets.count == 2)
  }

  // MARK: - Channels

  @Test func joinsAreSentOnceConnected() async throws {
    let (client, _) = await connectedClient()
    defer { Task { await client.disconnect() } }

    try await client.join(to: .sample("forsen"))
    try await client.join(to: .sample("forsen"))

    #expect(harness.sockets.value[0].sent.value.count(where: { $0 == "JOIN #forsen" }) == 1)
  }

  @Test func joiningBeforeTheConnectionIsUpJoinsLater() async throws {
    let client = harness.makeClient()
    defer { Task { await client.disconnect() } }

    try await client.join(to: .sample("forsen"))
    #expect(harness.sockets.value.isEmpty)

    await client.connect()

    #expect(harness.sockets.value[0].sent.value.last == "JOIN #forsen")
  }

  @Test func partedChannelsAreNotRejoined() async throws {
    let (client, recorder) = await connectedClient()
    defer { Task { await client.disconnect() } }

    try await client.join(to: .sample("forsen"))
    try await client.join(to: .sample("xqc"))
    try await client.part(from: .sample("forsen"))
    #expect(harness.sockets.value[0].sent.value.contains("PART #forsen"))

    harness.sockets.value[0].drop()
    await waitUntil("failure") {
      recorder.statuses.contains { if case .failed = $0 { true } else { false } }
    }
    await harness.advance(until: { harness.sockets.count == 2 })
    await waitUntil("rejoin") {
      harness.sockets.value.count == 2 && harness.sockets.value[1].sent.value.count >= 4
    }

    let rejoined = harness.sockets.value[1].sent.value.filter { $0.hasPrefix("JOIN") }
    #expect(rejoined == ["JOIN #xqc"])
  }

  // MARK: - Messages

  @Test func answersPingsWithPongs() async {
    let (client, _) = await connectedClient()
    defer { Task { await client.disconnect() } }

    harness.sockets.value[0].push(FakeSocket.ping)

    await waitUntil("pong") { harness.sockets.value[0].sent.value.contains("PONG :tmi.twitch.tv") }
  }

  @Test func channelSubscribersOnlyGetThatChannelsChat() async {
    let client = harness.makeClient()
    defer { Task { await client.disconnect() } }

    let forsen = await EventRecorder(client.subscribe(to: .sample("forsen")))
    let everything = await EventRecorder(client.subscribe(to: nil))
    await client.connect()

    harness.sockets.value[0].push(privateMessage(in: "xqc", text: "wrong channel"))
    harness.sockets.value[0].push(privateMessage(in: "forsen", text: "right channel"))

    await waitUntil("both messages") { everything.messages.count == 2 }
    await waitUntil("filtered message") { forsen.messages.count >= 1 }

    let texts = forsen.messages.compactMap { message -> String? in
      guard case let .privateMessage(pm) = message else { return nil }
      return pm.message
    }
    #expect(texts == ["right channel"])
  }
}
