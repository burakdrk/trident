import Foundation

struct EventChannel<Event: Sendable>: Sendable {
  let stream: AsyncStream<Event>
  let yield: @Sendable (Event) -> Void
  let finish: @Sendable () -> Void

  init(_: Event.Type, buffering: AsyncStream<Event>.Continuation.BufferingPolicy = .unbounded) {
    let (stream, continuation) = AsyncStream<Event>.makeStream(bufferingPolicy: buffering)
    self.stream = stream
    yield = { continuation.yield($0) }
    finish = { continuation.finish() }
  }
}

protocol EventEmitting {
  associatedtype Event: Sendable, Equatable
  var eventChannel: EventChannel<Event> { get }
}

extension EventEmitting {
  var events: AsyncStream<Event> { eventChannel.stream }
  func emit(_ event: Event) { eventChannel.yield(event) }
  func finishEvents() { eventChannel.finish() }
}
