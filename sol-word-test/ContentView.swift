import Combine
import SwiftUI

struct ContentView: View {
  @StateObject private var store = GameStore()
  @Environment(\.scenePhase) private var scenePhase
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var tab = 0
  @State private var showSettings = false
  @State private var showHowTo = false
  private let minute = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .top) {
        Studio.paper.ignoresSafeArea()
        if let issue = store.startupIssue {
          ContentUnavailableView {
            Label("A little snag", systemImage: "scissors")
          } description: {
            Text(issue)
          } actions: {
            Link(
              "Contact support", destination: URL(string: "mailto:harlen.interactive@gmail.com")!)
          }
        } else if let session = store.active {
          GameView(store: store, session: session).transition(.opacity)
        } else if !store.saved.hasLearned {
          WelcomeView(store: store).transition(.opacity)
        } else {
          studio.transition(.opacity)
        }
      }.frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
    }.foregroundStyle(Studio.ink).tint(Studio.red).preferredColorScheme(.light)
      .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: store.saved.activeID)
      .sheet(isPresented: $showSettings) { SettingsView(store: store) }
      .sheet(isPresented: $showHowTo) { HowToView() }
      .alert(
        "Progress notice",
        isPresented: Binding(
          get: { store.storageIssue != nil }, set: { if !$0 { store.storageIssue = nil } })
      ) {
        Button("OK") { store.storageIssue = nil }
      } message: {
        Text(store.storageIssue ?? "")
      }
      .onReceive(minute) { _ in store.refreshDate() }
      .onChange(of: scenePhase) { _, phase in
        if phase == .active {
          store.refreshDate()
          Task { await store.syncNotificationPermission() }
        }
      }
      .onAppear {
        #if DEBUG
          let args = ProcessInfo.processInfo.arguments
          if let i = args.firstIndex(of: "-capture-screen"), args.indices.contains(i + 1) {
            if args[i + 1] == "practice" { tab = 1 }
            if args[i + 1] == "stats" { tab = 2 }
          }
        #endif
      }
  }
  private var studio: some View {
    ScrollView {
      Group {
        switch tab {
        case 1: PracticeView(store: store)
        case 2: CutsView(store: store)
        default: TodayView(store: store) { showHowTo = true }
        }
      }.padding(.horizontal, 26).padding(.bottom, 28)
    }.scrollIndicators(.hidden)
      .safeAreaInset(edge: .top, spacing: 0) {
        HStack {
          Wordmark(size: 44)
          Spacer()
          IconButton(symbol: "gearshape", label: "Settings") { showSettings = true }
        }.padding(.horizontal, 26).padding(.top, 10).padding(.bottom, 14).background(Studio.paper)
      }
      .safeAreaInset(edge: .bottom, spacing: 0) {
        HStack(spacing: 0) {
          tabButton("Today", symbol: "sun.max", index: 0)
          tabButton("Practice", symbol: "scissors", index: 1)
          tabButton("Your cuts", symbol: "chart.bar.xaxis", index: 2)
        }.padding(.top, 12).padding(.bottom, 8).background(Studio.paper).overlay(alignment: .top) {
          Rectangle().fill(Studio.ink.opacity(0.12)).frame(height: 1)
        }
      }
  }
  private func tabButton(_ title: String, symbol: String, index: Int) -> some View {
    Button {
      tab = index
      Feedback.selection(store.settings)
    } label: {
      VStack(spacing: 6) {
        Image(systemName: symbol).font(
          .system(size: 20, weight: tab == index ? .semibold : .regular))
        Text(title).font(.caption.weight(tab == index ? .semibold : .regular))
      }.foregroundStyle(tab == index ? Studio.red : Studio.quiet).frame(maxWidth: .infinity).frame(
        minHeight: 50)
    }.buttonStyle(.plain).accessibilityIdentifier("tab-\(index)").accessibilityAddTraits(
      tab == index ? [.isSelected] : [])
  }
}

struct TodayView: View {
  @ObservedObject var store: GameStore
  let howTo: () -> Void
  private var session: GameSession { store.daily }
  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      Eyebrow(text: "A daily dose of wordplay", color: Studio.red)
      Text("A little cut.\nA little clever.").font(Studio.serif(44, italic: true)).tracking(-1.8)
        .fixedSize(horizontal: false, vertical: true).accessibilityAddTraits(.isHeader)
      Text("Three words. Six hidden answers.\nMake a little room for an aha.").font(.body)
        .foregroundStyle(Studio.quiet).lineSpacing(4)
      VStack(alignment: .leading, spacing: 20) {
        HStack {
          Eyebrow(text: "Today's three", color: Studio.ink)
          Spacer()
          Text("NO. \(session.edition)").font(Studio.mono(12)).foregroundStyle(Studio.red)
        }
        DottedRule()
        HStack(alignment: .top, spacing: 0) {
          round(0, title: "Warm-up")
          round(1, title: "A twist")
          round(2, title: "The finish")
        }
        StudioButton(
          title: session.finished
            ? "Your daily receipt"
            : (session.totalCuts > 0 ? "Pick up your scissors" : "Make today's cut"),
          symbol: session.finished ? "receipt" : "scissors"
        ) { store.startDaily() }.accessibilityIdentifier("play-daily")
        TimelineView(.periodic(from: .now, by: 60)) { context in
          HStack(spacing: 6) {
            Image(systemName: "clock")
            Text("Next edition in \(countdown(at: context.date))")
          }.font(.caption).foregroundStyle(Studio.quiet).frame(maxWidth: .infinity)
        }
      }.padding(22).background(Studio.card, in: RoundedRectangle(cornerRadius: 22)).overlay(
        RoundedRectangle(cornerRadius: 22).stroke(Studio.ink.opacity(0.08), lineWidth: 1))
      CutIllustration()
      HStack {
        Text("Every word hides a surprise.").font(Studio.serif(17, italic: true))
        Spacer()
        Button("How to play", action: howTo).font(.caption.weight(.semibold)).frame(minHeight: 44)
      }
    }.padding(.top, 12)
  }
  private func round(_ index: Int, title: String) -> some View {
    VStack(alignment: .leading, spacing: 7) {
      Text(session.rounds[index].status == .playing ? String(format: "%02d", index + 1) : "✓").font(
        Studio.serif(30)
      ).foregroundStyle(session.rounds[index].status == .playing ? Studio.ink : Studio.red)
      Text(title).font(.caption).foregroundStyle(Studio.quiet)
    }.frame(maxWidth: .infinity, alignment: .leading)
  }
  private func countdown(at date: Date) -> String {
    let seconds = max(0, Int(DailyEdition.nextRefresh(after: date).timeIntervalSince(date)))
    return "\(seconds / 3600)h \((seconds % 3600) / 60)m"
  }
}

struct PracticeView: View {
  @ObservedObject var store: GameStore
  var body: some View {
    VStack(alignment: .leading, spacing: 22) {
      Eyebrow(text: "The cutting room", color: Studio.red)
      Text("Keep your\nscissors sharp.").font(Studio.serif(41, italic: true)).tracking(-1.3)
        .fixedSize(horizontal: false, vertical: true).accessibilityAddTraits(.isHeader)
      Text("Twelve little puzzles. Four collections.\nA little more play, whenever you fancy.")
        .font(.body).foregroundStyle(Studio.quiet).lineSpacing(3)
      ForEach(Array(GameStore.packs.enumerated()), id: \.element.id) { index, pack in
        let session = store.practiceSession(pack)
        Button {
          store.startPractice(pack, replay: session?.finished == true)
        } label: {
          HStack(spacing: 17) {
            Text(String(format: "%02d", index + 1)).font(Studio.serif(32, italic: true))
              .foregroundStyle(Studio.red).frame(width: 43)
            VStack(alignment: .leading, spacing: 7) {
              Text(pack.title).font(Studio.serif(22))
              Text(pack.subtitle).font(.caption).foregroundStyle(Studio.quiet)
                .multilineTextAlignment(.leading)
              Eyebrow(
                text: session?.finished == true
                  ? "3 words · play again"
                  : (session != nil ? "3 words · continue" : "3 words · take a snip"))
            }
            Spacer(minLength: 0)
            Image(
              systemName: session?.finished == true ? "arrow.counterclockwise" : "arrow.up.right"
            ).foregroundStyle(Studio.quiet)
          }.padding(19).frame(maxWidth: .infinity, alignment: .leading).background(
            Studio.card, in: RoundedRectangle(cornerRadius: 17))
        }.buttonStyle(.plain).accessibilityIdentifier("pack-\(pack.id)")
      }
      Label("Everything lives on your phone.", systemImage: "wifi.slash").font(.caption)
        .foregroundStyle(Studio.quiet).padding(.top, 6)
    }.padding(.top, 10)
  }
}

struct CutsView: View {
  @ObservedObject var store: GameStore
  var body: some View {
    VStack(alignment: .leading, spacing: 23) {
      Eyebrow(text: "Your little collection", color: Studio.red)
      Text("Look what\nyou've cut.").font(Studio.serif(41, italic: true)).tracking(-1.3).fixedSize(
        horizontal: false, vertical: true
      ).accessibilityAddTraits(.isHeader)
      HStack(spacing: 12) {
        stat("Day streak", value: store.streak)
        stat("Words solved", value: store.solvedWords)
        stat("Clean days", value: store.cleanDays)
      }
      Text("A clean day means three first-try solves, with no hints or reveals.").font(.caption)
        .foregroundStyle(Studio.quiet).lineSpacing(3)
      DottedRule()
      Eyebrow(text: "Saved receipts")
      let finished = store.sessions.filter(\.finished).sorted {
        ($0.completedAt ?? .distantPast) > ($1.completedAt ?? .distantPast)
      }
      if finished.isEmpty {
        VStack(spacing: 15) {
          Image(systemName: "scissors").font(.system(size: 34)).foregroundStyle(Studio.red)
          Text("Your first cut is waiting.").font(Studio.serif(24, italic: true))
          Text("Finish a daily edition or a practice collection to start your stack of receipts.")
            .font(.body).foregroundStyle(Studio.quiet).multilineTextAlignment(.center)
          StudioButton(title: "Try today's three", symbol: "scissors") { store.startDaily() }
        }.padding(22).background(Studio.card, in: RoundedRectangle(cornerRadius: 20))
      } else {
        ForEach(finished) { session in
          Button {
            store.open(session)
          } label: {
            HStack {
              VStack(alignment: .leading, spacing: 8) {
                Text(session.mode == .daily ? "Edition \(session.edition)" : session.title).font(
                  Studio.serif(22))
                Text(session.isUnassisted ? "Unassisted" : "Assisted").font(.caption)
                  .foregroundStyle(Studio.quiet)
              }
              Spacer()
              Text(session.marks).font(Studio.mono(17)).foregroundStyle(Studio.red)
              Image(systemName: "arrow.up.right").foregroundStyle(Studio.quiet)
            }.padding(19).background(Studio.card, in: RoundedRectangle(cornerRadius: 15))
          }.buttonStyle(.plain)
        }
      }
    }.padding(.top, 10)
  }
  private func stat(_ label: String, value: Int) -> some View {
    VStack(alignment: .leading, spacing: 9) {
      Text("\(value)").font(Studio.serif(36)).foregroundStyle(Studio.red)
      Text(label).font(.caption).foregroundStyle(Studio.quiet).fixedSize(
        horizontal: false, vertical: true)
    }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 17).padding(
      .horizontal, 13
    ).background(Studio.card, in: RoundedRectangle(cornerRadius: 15))
  }
}
#Preview { ContentView() }
