import Combine
import Foundation
import UserNotifications

struct StudioSettings: Codable {
  var sound = true
  var haptics = true
  var reminders = false
  var reminderHour = 19
  var reminderMinute = 0
}

struct SavedStudio: Codable {
  var sessions: [GameSession] = []
  var settings = StudioSettings()
  var hasLearned = false
  var activeID: String?
}

struct PracticePack: Identifiable {
  let id: String
  let title: String
  let subtitle: String
  let symbol: String
}

@MainActor
final class GameStore: ObservableObject {
  static let packs = [
    PracticePack(
      id: "first-cuts", title: "First cuts", subtitle: "Find your feel for it.", symbol: "scissors"),
    PracticePack(
      id: "look-again", title: "Look again", subtitle: "Familiar words. Hidden surprises.",
      symbol: "eye"),
    PracticePack(
      id: "little-tricks", title: "Little tricks", subtitle: "A small change of perspective.",
      symbol: "sparkle"),
    PracticePack(
      id: "fine-cuts", title: "Fine cuts", subtitle: "For a sharper eye.", symbol: "scope"),
  ]
  @Published private(set) var catalog: [SnipPuzzle] = []
  @Published private(set) var saved = SavedStudio()
  @Published private(set) var now = Date()
  @Published var notice: String?
  @Published var startupIssue: String?
  @Published var storageIssue: String?
  private let defaults: UserDefaults
  private let saveKey = "snip.studio.v1"

  var sessions: [GameSession] { saved.sessions }
  var active: GameSession? { saved.sessions.first { $0.id == saved.activeID } }
  var settings: StudioSettings { saved.settings }
  var daily: GameSession {
    let fresh = DailyEdition.session(for: now, catalog: catalog)
    return saved.sessions.first { $0.id == fresh.id } ?? fresh
  }
  var completedDailies: [GameSession] {
    sessions.filter { $0.mode == .daily && $0.finished }.sorted { $0.id > $1.id }
  }
  var solvedWords: Int { sessions.filter(\.finished).reduce(0) { $0 + $1.solvedCount } }
  var cleanDays: Int { completedDailies.filter(\.isPerfect).count }
  var streak: Int { DailyEdition.streak(in: sessions, now: now) }

  init() {
    #if DEBUG
      let testing = ProcessInfo.processInfo.arguments.contains("-ui-testing")
      defaults = testing ? UserDefaults(suiteName: "SNIP.UITests")! : .standard
      if testing && ProcessInfo.processInfo.arguments.contains("-reset-state") {
        defaults.removePersistentDomain(forName: "SNIP.UITests")
      }
    #else
      defaults = .standard
    #endif
    do {
      guard let url = Bundle.main.url(forResource: "Puzzles", withExtension: "json") else {
        throw CocoaError(.fileNoSuchFile)
      }
      catalog = try JSONDecoder().decode([SnipPuzzle].self, from: Data(contentsOf: url))
      guard catalog.count >= 102, Set(catalog.map(\.id)).count == catalog.count,
        catalog.allSatisfy({ $0.validationIssue == nil }),
        catalog.filter({ $0.collection == "daily" }).count.isMultiple(of: 3)
      else {
        throw CocoaError(.coderReadCorrupt)
      }
      if let data = defaults.data(forKey: saveKey) {
        do {
          var loaded = try JSONDecoder().decode(SavedStudio.self, from: data)
          loaded.sessions = loaded.sessions.filter { $0.isValid(catalog: catalog) }
          if !loaded.sessions.contains(where: { $0.id == loaded.activeID }) {
            loaded.activeID = nil
          }
          if !(0...23).contains(loaded.settings.reminderHour)
            || !(0...59).contains(loaded.settings.reminderMinute)
          {
            loaded.settings.reminders = false
            loaded.settings.reminderHour = 19
            loaded.settings.reminderMinute = 0
          }
          saved = loaded
        } catch { storageIssue = "Your saved progress couldn't be read. A fresh studio is ready." }
      }
    } catch {
      startupIssue =
        "The puzzle collection couldn't be opened. Please reinstall SNIP or contact support."
    }
    #if DEBUG
      configureCapture()
    #endif
  }

  func refreshDate() { now = Date() }
  func puzzle(for session: GameSession) -> SnipPuzzle? {
    guard session.puzzleIDs.indices.contains(session.index) else { return nil }
    return catalog.first { $0.id == session.puzzleIDs[session.index] }
  }
  func puzzle(id: String) -> SnipPuzzle? { catalog.first { $0.id == id } }
  func startDaily() {
    saved.hasLearned = true
    open(daily)
  }
  func startPractice(_ pack: PracticePack, replay: Bool = false) {
    saved.hasLearned = true
    if !replay, let session = practiceSession(pack) {
      open(session)
      return
    }
    let id = "practice-\(pack.id)-\(UUID().uuidString)"
    open(
      GameSession(
        id: id, mode: .practice, edition: "", title: pack.title,
        puzzleIDs: catalog.filter { $0.collection == pack.id }.map(\.id)))
  }
  func practiceSession(_ pack: PracticePack) -> GameSession? {
    sessions.last {
      $0.mode == .practice
        && ($0.id == "practice-\(pack.id)" || $0.id.hasPrefix("practice-\(pack.id)-"))
    }
  }
  func open(_ session: GameSession) {
    replace(session)
    saved.activeID = session.id
    notice = nil
    persist()
  }
  func closeGame() {
    saved.activeID = nil
    notice = nil
    persist()
  }
  func finishLearning() {
    saved.hasLearned = true
    persist()
  }

  private func replace(_ session: GameSession) {
    if let index = saved.sessions.firstIndex(where: { $0.id == session.id }) {
      saved.sessions[index] = session
    } else {
      saved.sessions.append(session)
    }
  }
  private func mutate(_ change: (inout GameSession, SnipPuzzle) -> Void) {
    guard var session = active, let puzzle = puzzle(for: session) else { return }
    change(&session, puzzle)
    replace(session)
    persist()
  }
  func tapLetter(_ index: Int) {
    notice = nil
    mutate { $0.tap(index, puzzle: $1) }
    Feedback.selection(settings)
  }
  func select(_ range: ClosedRange<Int>) {
    notice = nil
    mutate { $0.select(range, puzzle: $1) }
  }
  func clearSelection() {
    mutate { session, _ in
      guard session.rounds[session.index].status == .playing else { return }
      session.rounds[session.index].lower = nil
      session.rounds[session.index].upper = nil
      session.rounds[session.index].pendingEndpoint = false
    }
    notice = nil
  }
  func submit() {
    mutate { session, puzzle in
      switch session.submit(puzzle: puzzle) {
      case .illegal:
        notice = "Cut at least three letters from inside the word. Leave at least three behind."
      case .incorrect:
        notice = "Not quite. Both pieces need to fit their clues."
        Feedback.incorrect(settings)
      case .correct:
        notice = nil
        Feedback.correct(settings)
      }
    }
  }
  func advance() {
    notice = nil
    mutate { session, _ in session.advance(now: now) }
  }
  func hint() {
    mutate { session, _ in session.hint() }
    Feedback.selection(settings)
  }
  func reveal() {
    notice = nil
    mutate { session, puzzle in session.reveal(puzzle: puzzle) }
  }
  func hintText(for session: GameSession, puzzle: SnipPuzzle) -> String? {
    switch session.rounds[session.index].hintLevel {
    case 1: return "The piece you cut out starts with \(puzzle.cut.prefix(1))."
    case 2: return "Cut out \(puzzle.cut.count) letters, starting with \(puzzle.cut.prefix(1))."
    default: return nil
    }
  }
  func setSound(_ value: Bool) {
    saved.settings.sound = value
    persist()
  }
  func setHaptics(_ value: Bool) {
    saved.settings.haptics = value
    persist()
  }
  func setReminderTime(hour: Int, minute: Int) async {
    saved.settings.reminderHour = hour
    saved.settings.reminderMinute = minute
    if saved.settings.reminders { await scheduleReminder() }
    persist()
  }
  func setReminders(_ value: Bool) async -> Bool {
    if !value {
      saved.settings.reminders = false
      UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [
        "snip.daily"
      ])
      persist()
      return true
    }
    do {
      let allowed = try await UNUserNotificationCenter.current().requestAuthorization(options: [
        .alert, .sound,
      ])
      guard allowed else {
        saved.settings.reminders = false
        persist()
        return false
      }
      saved.settings.reminders = true
      await scheduleReminder()
      persist()
      return true
    } catch {
      saved.settings.reminders = false
      persist()
      return false
    }
  }
  private func scheduleReminder() async {
    let content = UNMutableNotificationContent()
    content.title = "A little time for SNIP?"
    content.body = "Three small puzzles. One satisfying break."
    if settings.sound { content.sound = .default }
    let trigger = UNCalendarNotificationTrigger(
      dateMatching: DateComponents(hour: settings.reminderHour, minute: settings.reminderMinute),
      repeats: true)
    do {
      try await UNUserNotificationCenter.current().add(
        UNNotificationRequest(identifier: "snip.daily", content: content, trigger: trigger))
    } catch {
      saved.settings.reminders = false
      storageIssue = "The reminder couldn't be scheduled. You can try again in Settings."
    }
  }
  func syncNotificationPermission() async {
    let state = await UNUserNotificationCenter.current().notificationSettings()
    if state.authorizationStatus == .denied && saved.settings.reminders {
      _ = await setReminders(false)
    }
  }
  func resetProgress() {
    saved.sessions = []
    saved.activeID = nil
    saved.hasLearned = false
    notice = nil
    persist()
  }
  private func persist() {
    do { defaults.set(try JSONEncoder().encode(saved), forKey: saveKey) } catch {
      storageIssue = "Progress couldn't be saved. Please keep the app open and contact support."
    }
  }

  #if DEBUG
    private func configureCapture() {
      let args = ProcessInfo.processInfo.arguments
      guard let i = args.firstIndex(of: "-capture-screen"), args.indices.contains(i + 1) else {
        return
      }
      // Real practice data only. These launch arguments are absent from Release builds.
      saved.hasLearned = true
      let screen = args[i + 1]
      if ["game", "selected", "solved", "receipt"].contains(screen) {
        startPractice(Self.packs[0], replay: true)
        if screen != "game", let active, let puzzle = puzzle(for: active),
          let solution = puzzle.solution
        {
          select(solution)
        }
        if screen == "solved" { submit() }
        if screen == "receipt" {
          for _ in 0..<3 {
            if let active, let puzzle = puzzle(for: active), let solution = puzzle.solution {
              select(solution)
              submit()
              advance()
            }
          }
        }
      } else {
        saved.activeID = nil
      }
    }
  #endif
}
