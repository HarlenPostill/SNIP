import SwiftUI

struct GameView: View {
  @ObservedObject var store: GameStore
  let session: GameSession
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var showReveal = false
  @State private var showHowTo = false
  @State private var shareItems: [Any] = []
  @State private var showShare = false
  var body: some View {
    VStack(spacing: 0) {
      HStack {
        IconButton(symbol: "arrow.left", label: "Back to studio") { store.closeGame() }
          .accessibilityIdentifier("back-studio")
        Spacer()
        Wordmark(size: 42)
        Spacer()
        IconButton(symbol: "questionmark", label: "How to play") { showHowTo = true }
      }.padding(.horizontal, 24).padding(.top, 8).padding(.bottom, 16)
      if session.finished {
        ScrollView {
          ReceiptView(session: session).padding(.horizontal, 25).padding(.top, 5)
          Text("Spoiler-free. Brag-friendly.").font(Studio.serif(17, italic: true)).foregroundStyle(
            Studio.quiet
          ).padding(.top, 23).padding(.bottom, 20)
        }.scrollIndicators(.hidden)
        VStack(spacing: 12) {
          StudioButton(title: "Share your cuts", symbol: "square.and.arrow.up", action: share)
            .accessibilityIdentifier("share-receipt")
          Button("Back to the studio") { store.closeGame() }.font(.body).frame(minHeight: 44)
            .foregroundStyle(Studio.quiet)
        }.padding(.horizontal, 26).padding(.top, 10).padding(.bottom, 12)
      } else if let puzzle = store.puzzle(for: session) {
        puzzleContent(puzzle)
      }
    }
    .sheet(isPresented: $showHowTo) { HowToView() }
    .sheet(isPresented: $showShare) { ShareSheet(items: shareItems) }
    .confirmationDialog("Reveal this cut?", isPresented: $showReveal, titleVisibility: .visible) {
      Button("Reveal answer", role: .destructive) {
        withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8)) {
          store.reveal()
        }
      }
    } message: {
      Text("This word will be marked as revealed on your receipt. You can still finish the set.")
    }
  }
  private func puzzleContent(_ puzzle: SnipPuzzle) -> some View {
    let record = session.rounds[session.index]
    let complete = record.status != .playing
    let pieces = record.selection.flatMap { puzzle.pieces(for: $0) }
    return VStack(spacing: 0) {
      ScrollView {
        VStack(alignment: .leading, spacing: 21) {
          HStack {
            Eyebrow(
              text: session.mode == .daily ? "Edition \(session.edition)" : session.title,
              color: Studio.red)
            Spacer()
            Eyebrow(text: "\(session.index + 1) of \(session.puzzleIDs.count)")
          }
          HStack {
            Text(
              complete
                ? (record.status == .revealed ? "There it is." : "Nicely cut.") : "Make the cut."
            ).font(Studio.serif(36, italic: true)).tracking(-1.2).accessibilityAddTraits(.isHeader)
            Spacer()
            HStack(spacing: 6) {
              ForEach(session.rounds.indices, id: \.self) { i in
                Circle().fill(i <= session.index ? Studio.red : Studio.tint).frame(
                  width: 7, height: 7)
              }
            }.accessibilityHidden(true)
          }
          VStack(spacing: 0) {
            clue(label: "Cut out", text: puzzle.cutClue, answer: pieces?.cut, complete: complete)
            DottedRule().padding(.horizontal, 20)
            clue(
              label: "Leave behind", text: puzzle.keepClue, answer: pieces?.keep, complete: complete
            )
          }.background(Studio.card, in: RoundedRectangle(cornerRadius: 18))
          VStack(spacing: 13) {
            Eyebrow(text: complete ? "Two words. One cut." : "The word · \(puzzle.source)")
            LetterStrip(
              puzzle: puzzle, selection: record.selection, complete: complete, tap: store.tapLetter,
              select: store.select)
            if !complete {
              Text("Drag across a piece, or tap its first and last letter.").font(.caption)
                .foregroundStyle(Studio.quiet).multilineTextAlignment(.center).lineSpacing(3)
            } else {
              Text(
                record.status == .revealed
                  ? "A new way to see an old word." : "A little aha looks good on you."
              ).font(Studio.serif(17, italic: true)).foregroundStyle(Studio.quiet)
                .multilineTextAlignment(.center)
            }
          }.frame(maxWidth: .infinity).padding(.vertical, 9)
          if let notice = store.notice {
            Label(notice, systemImage: "arrow.counterclockwise").font(.callout).foregroundStyle(
              Studio.red
            ).accessibilityIdentifier("cut-feedback")
          }
          if let hint = store.hintText(for: session, puzzle: puzzle), !complete {
            Label(hint, systemImage: "sparkle").font(.callout).foregroundStyle(Studio.quiet)
              .accessibilityIdentifier("hint-feedback")
          }
          HStack {
            Eyebrow(
              text:
                "\(record.cuts) cut\(record.cuts == 1 ? "" : "s")\(record.assisted ? " · assisted" : "")"
            )
            Spacer()
            if !complete && record.selection != nil {
              Button("Clear") { store.clearSelection() }.font(.caption).foregroundStyle(
                Studio.quiet
              ).frame(minHeight: 44)
            }
          }
        }.padding(.horizontal, 26).padding(.top, 5).padding(.bottom, 15)
      }.scrollIndicators(.hidden)
      VStack(spacing: 8) {
        StudioButton(
          title: complete
            ? (session.index == session.puzzleIDs.count - 1 ? "Your little receipt" : "Next word")
            : "Snip", symbol: complete ? "arrow.right" : "scissors",
          enabled: complete || record.selection.map(puzzle.isLegal) == true
        ) {
          withAnimation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.82)) {
            if complete { store.advance() } else { store.submit() }
          }
        }.accessibilityIdentifier("commit-cut")
        if !complete {
          HStack {
            Button {
              store.hint()
            } label: {
              Label(
                record.hintLevel == 0 ? "A little hint" : "One more hint", systemImage: "sparkle"
              ).font(.caption).frame(minHeight: 44)
            }.disabled(record.hintLevel >= 2).accessibilityIdentifier("hint-button")
            Spacer()
            Button("Reveal") { showReveal = true }.font(.caption).foregroundStyle(Studio.quiet)
              .frame(minHeight: 44).accessibilityIdentifier("reveal-button")
          }
        } else {
          Text("Take your time. The next word can wait.").font(.caption).foregroundStyle(
            Studio.quiet
          ).frame(minHeight: 35)
        }
      }.padding(.horizontal, 26).padding(.top, 8).padding(.bottom, 10).background(Studio.paper)
    }
  }
  private func clue(label: String, text: String, answer: String?, complete: Bool) -> some View {
    VStack(alignment: .leading, spacing: 11) {
      HStack {
        Eyebrow(text: label, color: label == "Cut out" ? Studio.red : Studio.quiet)
        Spacer()
        if complete {
          Image(systemName: "checkmark").font(.caption.weight(.semibold)).foregroundStyle(
            Studio.red
          ).accessibilityLabel("Answer shown")
        }
      }
      Text(text).font(.title3.weight(.medium)).fixedSize(horizontal: false, vertical: true)
      Text(answer?.isEmpty == false ? answer! : "· · ·").font(
        .system(size: 24, weight: .medium, design: .monospaced)
      ).tracking(2).foregroundStyle(Studio.red).lineLimit(2).minimumScaleFactor(0.65)
        .accessibilityIdentifier(label == "Cut out" ? "cut-word" : "keep-word")
    }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
  }
  private func share() {
    let renderer = ImageRenderer(
      content: ReceiptView(session: session).padding(30).frame(width: 430).background(Studio.paper)
        .environment(\.colorScheme, .light).environment(\.sizeCategory, .large))
    renderer.scale = 3
    if let image = renderer.uiImage {
      shareItems = [image, session.shareText]
    } else {
      shareItems = [session.shareText]
    }
    showShare = true
  }
}

struct LetterStrip: View {
  let puzzle: SnipPuzzle
  let selection: ClosedRange<Int>?
  let complete: Bool
  let tap: (Int) -> Void
  let select: (ClosedRange<Int>) -> Void
  @Environment(\.accessibilityReduceMotion) private var reduceMotion
  @State private var lastDrag: ClosedRange<Int>?
  @Namespace private var letters
  private var columns: Int {
    puzzle.source.count <= 7 ? puzzle.source.count : (puzzle.source.count + 1) / 2
  }
  private var rows: Int { puzzle.source.count <= 7 ? 1 : 2 }
  var body: some View {
    Group {
      if complete, let selection {
        HStack(spacing: 16) {
          wordPiece(puzzle.letters.indices.filter { !selection.contains($0) }, accent: false)
          wordPiece(Array(selection), accent: true).rotationEffect(.degrees(reduceMotion ? 0 : -7))
        }.frame(maxWidth: .infinity).padding(.vertical, 12).accessibilityElement(children: .ignore)
          .accessibilityLabel("\(puzzle.keep) remains. \(puzzle.cut) is cut out.")
      } else {
        GeometryReader { geometry in
          VStack(spacing: 10) {
            ForEach(0..<rows, id: \.self) { row in
              HStack(spacing: 0) {
                ForEach((row * columns)..<min((row + 1) * columns, puzzle.source.count), id: \.self)
                { index in
                  Button {
                    tap(index)
                  } label: {
                    Text(puzzle.letters[index]).font(
                      .system(size: 32, weight: .medium, design: .monospaced)
                    ).foregroundStyle(
                      selection?.contains(index) == true ? Studio.paper : Studio.ink
                    ).frame(width: geometry.size.width / CGFloat(columns), height: 66).background(
                      selection?.contains(index) == true ? Studio.red : Studio.card
                    ).matchedGeometryEffect(id: index, in: letters)
                  }.buttonStyle(.plain).accessibilityLabel(
                    "\(puzzle.letters[index]), letter \(index + 1)"
                  ).accessibilityValue(
                    selection?.contains(index) == true ? "Selected" : "Not selected"
                  ).accessibilityHint("Select the first and last letter of the piece to cut")
                    .accessibilityIdentifier("letter-\(index)")
                }
                if row == rows - 1 && puzzle.source.count % columns != 0 { Spacer(minLength: 0) }
              }.overlay(alignment: .top) { DottedRule() }.overlay(alignment: .bottom) {
                DottedRule()
              }
            }
          }.simultaneousGesture(
            DragGesture(minimumDistance: 10).onChanged { value in
              let a = letter(at: value.startLocation, width: geometry.size.width)
              let b = letter(at: value.location, width: geometry.size.width)
              let range = min(a, b)...max(a, b)
              if range != lastDrag {
                lastDrag = range
                select(range)
              }
            }.onEnded { _ in lastDrag = nil })
        }.frame(height: CGFloat(rows) * 66 + CGFloat(rows - 1) * 10)
      }
    }
  }
  private func letter(at point: CGPoint, width: CGFloat) -> Int {
    let row = min(rows - 1, max(0, Int(point.y / 76)))
    let column = min(columns - 1, max(0, Int(point.x / max(1, width / CGFloat(columns)))))
    return min(puzzle.source.count - 1, row * columns + column)
  }
  private func wordPiece(_ indices: [Int], accent: Bool) -> some View {
    HStack(spacing: 0) {
      ForEach(indices, id: \.self) { index in
        Text(puzzle.letters[index]).font(
          .system(size: puzzle.source.count > 8 ? 24 : 29, weight: .medium, design: .monospaced)
        ).padding(.horizontal, 3).padding(.vertical, 17).foregroundStyle(
          accent ? Studio.paper : Studio.ink
        ).matchedGeometryEffect(id: index, in: letters)
      }
    }.padding(.horizontal, 11).background(accent ? Studio.red : Studio.card).overlay(
      Rectangle().stroke(
        accent ? Studio.red : Studio.quiet.opacity(0.4),
        style: StrokeStyle(lineWidth: 1, dash: [3, 3])))
  }
}

struct ReceiptView: View {
  let session: GameSession
  var body: some View {
    VStack(spacing: 23) {
      HStack {
        Eyebrow(text: "The little cut club")
        Spacer()
        Image(systemName: "scissors").foregroundStyle(Studio.red)
      }
      DottedRule()
      VStack(spacing: 10) {
        Text(
          session.isPerfect
            ? "Clean cut."
            : (session.solvedCount == session.rounds.count ? "Nicely cut." : "A little wiser.")
        ).font(Studio.serif(41, italic: true)).tracking(-1.5)
        Text(session.mode == .daily ? "EDITION \(session.edition)" : session.title.uppercased())
          .font(Studio.mono(12)).tracking(2).foregroundStyle(Studio.quiet)
      }
      Text(session.marks).font(.system(size: 47, weight: .regular, design: .monospaced))
        .foregroundStyle(Studio.red).lineLimit(1).minimumScaleFactor(0.6).padding(.vertical, 10)
        .accessibilityIdentifier("receipt-marks")
      VStack(spacing: 12) {
        receiptRow("Words solved", value: "\(session.solvedCount) / \(session.rounds.count)")
        receiptRow("Cuts made", value: "\(session.totalCuts)")
        receiptRow(
          "A helping hand", value: session.isUnassisted ? "None needed" : "Hint or reveal used")
      }
      DottedRule()
      Text("Can you make the cut?").font(Studio.serif(23, italic: true))
      Wordmark(size: 48)
      Eyebrow(text: "A small daily pleasure.")
    }.padding(.horizontal, 25).padding(.vertical, 34).frame(maxWidth: .infinity).background(
      ReceiptShape().fill(Studio.card)
    ).overlay(ReceiptShape().stroke(Studio.ink.opacity(0.08), lineWidth: 1))
  }
  private func receiptRow(_ label: String, value: String) -> some View {
    HStack(alignment: .top) {
      Text(label).foregroundStyle(Studio.quiet)
      Spacer(minLength: 12)
      Text(value).multilineTextAlignment(.trailing)
    }.font(.caption)
  }
}
