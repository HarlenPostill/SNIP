import Foundation

struct SnipPuzzle: Codable, Identifiable, Equatable, Sendable {
  let id: String
  let source: String
  let cut: String
  let keep: String
  let cutClue: String
  let keepClue: String
  let difficulty: Int
  let collection: String

  var letters: [String] { source.map(String.init) }
  var solution: ClosedRange<Int>? {
    for start in 1..<max(1, source.count - 3) {
      let end = start + cut.count - 1
      guard end < source.count - 1 else { continue }
      let selection = start...end
      if pieces(for: selection) == WordPieces(cut: cut, keep: keep) { return selection }
    }
    return nil
  }

  func pieces(for range: ClosedRange<Int>) -> WordPieces? {
    let chars = Array(source)
    guard range.lowerBound >= 0, range.upperBound < chars.count else { return nil }
    return WordPieces(
      cut: String(chars[range]),
      keep: String(chars[..<range.lowerBound]) + String(chars[(range.upperBound + 1)...]))
  }

  func isLegal(_ range: ClosedRange<Int>) -> Bool {
    range.lowerBound > 0 && range.upperBound < source.count - 1 && range.count >= 3
      && source.count - range.count >= 3
  }

  var validationIssue: String? {
    guard source.count >= 6, source.count <= 12, cut.count >= 3, keep.count >= 3,
      [source, cut, keep].allSatisfy({ $0.allSatisfy { $0.isASCII && $0.isUppercase } }),
      !cutClue.isEmpty, !keepClue.isEmpty, (1...3).contains(difficulty),
      let solution, isLegal(solution)
    else { return "Invalid puzzle: \(id)" }
    return nil
  }
}

struct WordPieces: Equatable, Sendable {
  let cut: String
  let keep: String
}

enum PlayMode: String, Codable, Sendable { case daily, practice }
enum RoundStatus: String, Codable, Sendable { case playing, solved, revealed }

struct RoundRecord: Codable, Equatable, Sendable {
  var cuts = 0
  var hintLevel = 0
  var status: RoundStatus = .playing
  var lower: Int?
  var upper: Int?
  var pendingEndpoint = false
  var selection: ClosedRange<Int>? {
    guard let lower, let upper else { return nil }
    return min(lower, upper)...max(lower, upper)
  }
  var assisted: Bool { hintLevel > 0 || status == .revealed }
}

struct GameSession: Codable, Identifiable, Equatable, Sendable {
  let id: String
  let mode: PlayMode
  let edition: String
  let title: String
  let puzzleIDs: [String]
  var rounds: [RoundRecord]
  var index = 0
  var finished = false
  var completedAt: Date?

  init(id: String, mode: PlayMode, edition: String, title: String, puzzleIDs: [String]) {
    self.id = id
    self.mode = mode
    self.edition = edition
    self.title = title
    self.puzzleIDs = puzzleIDs
    rounds = puzzleIDs.map { _ in RoundRecord() }
  }
  var totalCuts: Int { rounds.reduce(0) { $0 + $1.cuts } }
  var solvedCount: Int { rounds.filter { $0.status == .solved }.count }
  var isUnassisted: Bool { solvedCount == rounds.count && !rounds.contains(where: \.assisted) }
  var isPerfect: Bool { isUnassisted && totalCuts == rounds.count }
  var marks: String {
    rounds.map { $0.status == .revealed ? "—" : "\($0.cuts)\($0.hintLevel > 0 ? "*" : "")" }.joined(
      separator: " · ")
  }

  mutating func tap(_ index: Int, puzzle: SnipPuzzle) {
    guard rounds[self.index].status == .playing, puzzle.letters.indices.contains(index) else {
      return
    }
    if rounds[self.index].pendingEndpoint {
      rounds[self.index].upper = index
      rounds[self.index].pendingEndpoint = false
    } else {
      rounds[self.index].lower = index
      rounds[self.index].upper = index
      rounds[self.index].pendingEndpoint = true
    }
  }

  mutating func select(_ range: ClosedRange<Int>, puzzle: SnipPuzzle) {
    guard rounds[index].status == .playing, range.lowerBound >= 0,
      range.upperBound < puzzle.source.count
    else { return }
    rounds[index].lower = range.lowerBound
    rounds[index].upper = range.upperBound
    rounds[index].pendingEndpoint = false
  }

  enum CutResult: Equatable { case illegal, incorrect, correct }
  mutating func submit(puzzle: SnipPuzzle) -> CutResult {
    guard rounds[index].status == .playing, let range = rounds[index].selection,
      puzzle.isLegal(range)
    else { return .illegal }
    rounds[index].cuts += 1
    guard puzzle.pieces(for: range) == WordPieces(cut: puzzle.cut, keep: puzzle.keep) else {
      return .incorrect
    }
    rounds[index].status = .solved
    return .correct
  }

  mutating func hint() {
    guard rounds[index].status == .playing else { return }
    rounds[index].hintLevel = min(2, rounds[index].hintLevel + 1)
  }

  mutating func reveal(puzzle: SnipPuzzle) {
    guard rounds[index].status == .playing, let solution = puzzle.solution else { return }
    select(solution, puzzle: puzzle)
    rounds[index].status = .revealed
  }

  mutating func advance(now: Date) {
    guard !finished, rounds[index].status != .playing else { return }
    if index < puzzleIDs.count - 1 {
      index += 1
    } else {
      finished = true
      completedAt = now
    }
  }

  var shareText: String {
    let heading = mode == .daily ? "SNIP #\(edition)" : "SNIP · \(title)"
    return
      "\(heading)\n✂︎ \(marks)\n\(solvedCount)/\(rounds.count) solved · \(isUnassisted ? "unassisted" : "assisted")\nCan you make the cut?\nhttps://snip.hrln-interactive.com"
  }

  func isValid(catalog: [SnipPuzzle]) -> Bool {
    guard !puzzleIDs.isEmpty, puzzleIDs.count == rounds.count, rounds.indices.contains(index),
      Set(puzzleIDs).count == puzzleIDs.count,
      !(finished && rounds.contains { $0.status == .playing }),
      !finished || completedAt != nil
    else { return false }
    for (i, id) in puzzleIDs.enumerated() {
      guard let puzzle = catalog.first(where: { $0.id == id }), rounds[i].cuts >= 0,
        (0...2).contains(rounds[i].hintLevel)
      else { return false }
      let record = rounds[i]
      if let range = record.selection, puzzle.pieces(for: range) == nil { return false }
      if record.status != .playing {
        guard let range = record.selection,
          puzzle.pieces(for: range) == WordPieces(cut: puzzle.cut, keep: puzzle.keep)
        else { return false }
      }
      if i < index && record.status == .playing { return false }
    }
    return true
  }
}

enum DailyEdition {
  static var calendar: Calendar {
    var c = Calendar(identifier: .gregorian)
    c.timeZone = TimeZone(secondsFromGMT: 0)!
    return c
  }
  static let epoch = calendar.date(from: DateComponents(year: 2026, month: 10, day: 14))!
  static func key(for date: Date) -> String {
    let c = calendar.dateComponents([.year, .month, .day], from: date)
    return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
  }
  static func number(for date: Date) -> Int {
    max(
      1,
      (calendar.dateComponents([.day], from: epoch, to: calendar.startOfDay(for: date)).day ?? 0)
        + 1)
  }
  static func nextRefresh(after date: Date) -> Date {
    calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date))!
  }
  static func session(for date: Date, catalog: [SnipPuzzle]) -> GameSession {
    let dailies = catalog.filter { $0.collection == "daily" }
    let n = number(for: date) - 1
    // A 30-day editorial cycle. Bundle expansion can extend the cycle without a server.
    let days = dailies.count / 3
    let start = (n % max(1, days)) * 3
    let ids = Array(dailies[start..<min(start + 3, dailies.count)]).map(\.id)
    return GameSession(
      id: "daily-\(key(for: date))", mode: .daily, edition: String(format: "%03d", n + 1),
      title: "Today's three", puzzleIDs: ids)
  }
  static func streak(in sessions: [GameSession], now: Date) -> Int {
    let completed = Set(
      sessions.filter { $0.mode == .daily && $0.finished && $0.solvedCount == $0.rounds.count }.map
      { String($0.id.dropFirst(6)) })
    var day = calendar.startOfDay(for: now)
    if !completed.contains(key(for: day)) {
      day = calendar.date(byAdding: .day, value: -1, to: day)!
    }
    var count = 0
    while completed.contains(key(for: day)) {
      count += 1
      day = calendar.date(byAdding: .day, value: -1, to: day)!
    }
    return count
  }
}
