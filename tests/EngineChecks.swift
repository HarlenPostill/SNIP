import Foundation

@main
struct EngineChecks {
  static func main() throws {
    let url = URL(fileURLWithPath: CommandLine.arguments[1])
    let catalog = try JSONDecoder().decode([SnipPuzzle].self, from: Data(contentsOf: url))
    var checks = 0
    func check(_ condition: @autoclosure () -> Bool, _ label: String) {
      precondition(condition(), label)
      checks += 1
    }
    check(catalog.count == 102, "102 editorial puzzles")
    check(Set(catalog.map(\.source)).count == catalog.count, "Distinct source words")
    for p in catalog {
      check(p.validationIssue == nil, "Puzzle validity: \(p.id)")
      check(p.solution.map(p.isLegal) == true, "Legal interior solution: \(p.id)")
      var game = GameSession(
        id: "check", mode: .practice, edition: "", title: "Check", puzzleIDs: [p.id])
      game.select(p.solution!, puzzle: p)
      check(game.submit(puzzle: p) == .correct, "Accept correct cut: \(p.id)")
      check(game.submit(puzzle: p) == .illegal, "No repeat scoring on solved word")
      game.advance(now: Date())
      check(game.finished && game.isPerfect && game.totalCuts == 1, "Clean solve accounting")
      check(game.isValid(catalog: catalog), "Valid completed save")
      let restored = try JSONDecoder().decode(GameSession.self, from: JSONEncoder().encode(game))
      check(restored == game, "Save round trip")
      check(
        !game.shareText.contains(p.source)
          && !game.shareText.split(separator: "\n").prefix(3).contains(where: { $0.contains(p.cut) }
          ), "Spoiler-free results")
    }
    let p = catalog.first { $0.id == "pirate" }!
    var game = GameSession(
      id: "attempts", mode: .practice, edition: "", title: "Check", puzzleIDs: [p.id])
    game.tap(4, puzzle: p)
    game.tap(2, puzzle: p)
    check(game.rounds[0].selection == 2...4, "Reversed endpoints")
    game.select(0...2, puzzle: p)
    check(
      game.submit(puzzle: p) == .illegal && game.totalCuts == 0,
      "No charge for illegal endpoint cut")
    game.select(1...3, puzzle: p)
    check(
      game.submit(puzzle: p) == .incorrect && game.totalCuts == 1, "Wrong committed cut counted")
    game.hint()
    game.hint()
    game.hint()
    check(game.rounds[0].hintLevel == 2, "Hints cap at two")
    game.select(p.solution!, puzzle: p)
    _ = game.submit(puzzle: p)
    game.advance(now: Date())
    check(
      game.finished && !game.isUnassisted && !game.isPerfect && game.totalCuts == 2,
      "Hints prevent clean score")
    var revealed = GameSession(
      id: "revealed", mode: .practice, edition: "", title: "Check", puzzleIDs: [p.id])
    revealed.reveal(puzzle: p)
    revealed.advance(now: Date())
    check(
      revealed.solvedCount == 0 && revealed.marks == "—" && !revealed.isUnassisted,
      "Reveal is distinct from solve")
    let iso = ISO8601DateFormatter()
    let before = iso.date(from: "2026-10-14T23:59:59Z")!
    let after = iso.date(from: "2026-10-15T00:00:00Z")!
    check(DailyEdition.key(for: before) == "2026-10-14", "UTC key before boundary")
    check(DailyEdition.key(for: after) == "2026-10-15", "UTC key after boundary")
    check(DailyEdition.nextRefresh(after: before) == after, "Exact midnight refresh")
    var editions = [GameSession]()
    for day in 0..<30 {
      let date = DailyEdition.calendar.date(byAdding: .day, value: day, to: DailyEdition.epoch)!
      let session = DailyEdition.session(for: date, catalog: catalog)
      check(
        session.puzzleIDs.count == 3 && session.isValid(catalog: catalog),
        "Three valid daily puzzles")
      editions.append(session)
    }
    check(Set(editions.flatMap(\.puzzleIDs)).count == 90, "No repeat source in first 30 days")
    for day in 0..<3 {
      var s = editions[day]
      for _ in 0..<3 {
        let p = catalog.first { $0.id == s.puzzleIDs[s.index] }!
        s.select(p.solution!, puzzle: p)
        _ = s.submit(puzzle: p)
        s.advance(
          now: DailyEdition.calendar.date(byAdding: .day, value: day, to: DailyEdition.epoch)!)
      }
      editions[day] = s
    }
    let day3 = DailyEdition.calendar.date(byAdding: .day, value: 2, to: DailyEdition.epoch)!
    check(DailyEdition.streak(in: editions, now: day3) == 3, "Consecutive solved day streak")
    check(
      DailyEdition.streak(
        in: editions, now: DailyEdition.calendar.date(byAdding: .day, value: 1, to: day3)!) == 3,
      "Streak survives until next day's end")
    check(
      DailyEdition.streak(
        in: editions, now: DailyEdition.calendar.date(byAdding: .day, value: 2, to: day3)!) == 0,
      "Missed day breaks streak")
    var corrupt = game
    corrupt.index = 100
    check(!corrupt.isValid(catalog: catalog), "Reject corrupt saved index")
    var incomplete = GameSession(
      id: "bad", mode: .daily, edition: "001", title: "Bad", puzzleIDs: [p.id])
    incomplete.finished = true
    incomplete.completedAt = Date()
    check(!incomplete.isValid(catalog: catalog), "Reject completed save with unresolved word")
    print("PASS: \(checks) engine/content/persistence/calendar assertions")
  }
}
