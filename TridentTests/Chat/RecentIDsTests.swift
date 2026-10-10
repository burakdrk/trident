import Testing
@testable import Trident

struct RecentIDsTests {
  @Test func reportsRepeats() {
    var ids = RecentIDs(capacity: 10)

    let first = ids.insert("a")
    let again = ids.insert("a")
    let other = ids.insert("b")

    #expect(first)
    #expect(!again)
    #expect(other)
  }

  @Test func forgetsTheOldestOnceFull() {
    var ids = RecentIDs(capacity: 2)

    ids.insert("a")
    ids.insert("b")
    ids.insert("c") // pushes out "a"

    let b = ids.insert("b")
    let c = ids.insert("c")
    let a = ids.insert("a")

    #expect(!b)
    #expect(!c)
    #expect(a)
  }
}
