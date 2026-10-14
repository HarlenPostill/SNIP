import SwiftUI

struct WelcomeView: View {
  @ObservedObject var store: GameStore
  @State private var page = 0
  private let titles = [
    "Every word hides\na little more.", "Keep both pieces.\nFind both answers.",
    "Three little puzzles.\nA lovely little habit.",
  ]
  private let descriptions = [
    "Cut one small word out of a bigger one. The remaining letters make a second word.",
    "Follow the two clues. Select one continuous piece from inside the word, then tap Snip.",
    "Try today's edition, practise whenever you like, and share your cuts without spoiling the answers.",
  ]
  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Wordmark(size: 50)
        Spacer()
        Button("Skip") { store.finishLearning() }.foregroundStyle(Studio.quiet).frame(minHeight: 44)
          .accessibilityIdentifier("skip-welcome")
      }.padding(.horizontal, 27).padding(.top, 14)
      ScrollView {
        VStack(alignment: .leading, spacing: 26) {
          Eyebrow(text: "Welcome to the little cut club", color: Studio.red)
          Text(titles[page]).font(Studio.serif(41, italic: true)).tracking(-1.3).fixedSize(
            horizontal: false, vertical: true)
          CutIllustration().padding(.vertical, 22)
          Text(descriptions[page]).font(.title3).foregroundStyle(Studio.quiet).lineSpacing(5)
          DottedRule()
          Text(
            page == 0
              ? "PIRATE → PIE + RAT"
              : (page == 1
                ? "No rearranging. No wasted letters." : "Take your time. Enjoy the aha.")
          ).font(Studio.mono(13)).foregroundStyle(Studio.red)
        }.padding(.horizontal, 28).padding(.top, 38).padding(.bottom, 20)
      }.scrollIndicators(.hidden)
      VStack(spacing: 21) {
        HStack(spacing: 8) {
          ForEach(0..<3) { i in
            Circle().fill(i == page ? Studio.red : Studio.tint).frame(width: 7, height: 7)
          }
        }.accessibilityLabel("Introduction page \(page + 1) of 3")
        StudioButton(
          title: page == 2 ? "Try your first cuts" : "A little more",
          symbol: page == 2 ? "scissors" : "arrow.right"
        ) { if page < 2 { page += 1 } else { store.startPractice(GameStore.packs[0]) } }
        .accessibilityIdentifier("welcome-next")
      }.padding(27)
    }
  }
}

struct HowToView: View {
  @Environment(\.dismiss) private var dismiss
  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 24) {
          Text("A little how-to.").font(Studio.serif(35, italic: true))
          CutIllustration()
          rule(
            "01", "Read both clues.",
            "One describes the piece you cut out. The other describes what you leave behind.")
          rule(
            "02", "Pick one continuous piece.",
            "Drag across letters, or tap the first and last letter. Cut from inside the word. Both pieces need at least three letters."
          )
          rule(
            "03", "Make the cut.",
            "The remaining letters close the gap, keeping their order. Both new words must match their clues."
          )
          DottedRule()
          Text(
            "Every committed cut counts. Hints add an asterisk to your receipt. Reveals appear as a dash and don't count as a solve. Three first-try solves without help make a clean day."
          ).font(.body).foregroundStyle(Studio.quiet).lineSpacing(4)
          Text(
            "Daily editions change at midnight UTC. Your phone shows a countdown. Practice collections can be replayed anytime."
          ).font(.caption).foregroundStyle(Studio.quiet).lineSpacing(3)
        }.padding(27)
      }.background(Studio.paper).navigationTitle("How to play").navigationBarTitleDisplayMode(
        .inline
      ).toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
    }.tint(Studio.red).preferredColorScheme(.light)
  }
  private func rule(_ number: String, _ title: String, _ detail: String) -> some View {
    HStack(alignment: .top, spacing: 17) {
      Text(number).font(Studio.serif(25, italic: true)).foregroundStyle(Studio.red)
      VStack(alignment: .leading, spacing: 9) {
        Text(title).font(.headline)
        Text(detail).font(.body).foregroundStyle(Studio.quiet).lineSpacing(3)
      }
    }
  }
}
