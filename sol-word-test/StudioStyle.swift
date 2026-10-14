import SwiftUI

enum Studio {
  static let paper = Color(red: 0.963, green: 0.946, blue: 0.903)
  static let ink = Color(red: 0.16, green: 0.17, blue: 0.14)
  static let red = Color(red: 0.77, green: 0.23, blue: 0.13)
  static let quiet = Color(red: 0.39, green: 0.40, blue: 0.34)
  static let card = Color(red: 0.993, green: 0.982, blue: 0.945)
  static let tint = Color(red: 0.916, green: 0.893, blue: 0.827)
  static func serif(_ size: CGFloat, italic: Bool = false) -> Font {
    .custom(italic ? "Georgia-Italic" : "Georgia", size: size, relativeTo: .largeTitle)
  }
  static func mono(_ size: CGFloat = 11) -> Font {
    .system(size: size, weight: .medium, design: .monospaced)
  }
}
struct Eyebrow: View {
  let text: String
  var color: Color = Studio.quiet
  var body: some View {
    Text(text.uppercased()).font(Studio.mono()).tracking(1.5).foregroundStyle(color).fixedSize(
      horizontal: false, vertical: true)
  }
}
struct Wordmark: View {
  var size: CGFloat = 48
  var body: some View {
    Text("snip.").font(Studio.serif(size, italic: true)).tracking(-size * 0.06).foregroundStyle(
      Studio.ink
    ).accessibilityLabel("SNIP")
  }
}
struct Perforation: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    p.move(to: CGPoint(x: 0, y: rect.midY))
    p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
    return p
  }
}
struct DottedRule: View {
  var body: some View {
    Perforation().stroke(Studio.quiet.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [3, 4]))
      .frame(height: 1).accessibilityHidden(true)
  }
}
struct ReceiptShape: Shape {
  func path(in rect: CGRect) -> Path {
    var p = Path()
    let step: CGFloat = 12
    p.move(to: CGPoint(x: 0, y: 8))
    p.addLine(to: CGPoint(x: rect.maxX, y: 8))
    p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 8))
    var x = rect.maxX
    while x > 0 {
      p.addLine(to: CGPoint(x: max(0, x - step / 2), y: rect.maxY))
      p.addLine(to: CGPoint(x: max(0, x - step), y: rect.maxY - 8))
      x -= step
    }
    p.addLine(to: CGPoint(x: 0, y: 8))
    p.closeSubpath()
    return p
  }
}
struct StudioButton: View {
  let title: String
  var symbol = "arrow.right"
  var enabled = true
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      HStack(spacing: 12) {
        Text(title).font(.body.weight(.semibold))
        Spacer(minLength: 0)
        Image(systemName: symbol).font(.body.weight(.medium))
      }
      .padding(.horizontal, 22).padding(.vertical, 18).frame(minHeight: 58).foregroundStyle(
        Studio.paper
      ).background(Studio.ink, in: RoundedRectangle(cornerRadius: 15))
    }.buttonStyle(.plain).disabled(!enabled).opacity(enabled ? 1 : 0.38)
  }
}
struct IconButton: View {
  let symbol: String
  let label: String
  let action: () -> Void
  var body: some View {
    Button(action: action) {
      Image(systemName: symbol).font(.system(size: 18, weight: .medium)).frame(
        width: 46, height: 46
      ).foregroundStyle(Studio.ink).background(Studio.tint.opacity(0.48), in: Circle())
    }.buttonStyle(.plain).accessibilityLabel(label)
  }
}
struct PaperWord: View {
  let word: String
  var accent = false
  var size: CGFloat = 28
  var body: some View {
    Text(word).font(.system(size: size, weight: .medium, design: .monospaced)).tracking(4)
      .foregroundStyle(accent ? Studio.paper : Studio.ink).padding(.horizontal, 15).padding(
        .vertical, 13
      ).background(accent ? Studio.red : Studio.card).overlay(
        Rectangle().stroke(
          accent ? Studio.red : Studio.quiet.opacity(0.4),
          style: StrokeStyle(lineWidth: 1, dash: [3, 3])))
  }
}
struct CutIllustration: View {
  var body: some View {
    HStack(spacing: 12) {
      PaperWord(word: "PIE", size: 25).rotationEffect(.degrees(-5)).offset(y: 8)
      Image(systemName: "scissors").font(.system(size: 24)).foregroundStyle(Studio.red)
        .rotationEffect(.degrees(-25))
      PaperWord(word: "RAT", accent: true, size: 25).rotationEffect(.degrees(7)).offset(y: -6)
    }.padding(.vertical, 18).frame(maxWidth: .infinity).accessibilityElement(children: .ignore)
      .accessibilityLabel("PIRATE can become PIE and RAT with one cut")
  }
}
struct ShareSheet: UIViewControllerRepresentable {
  let items: [Any]
  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: items, applicationActivities: nil)
  }
  func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
