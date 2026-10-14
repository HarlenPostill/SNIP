import XCTest

@MainActor
final class SNIPUITests: XCTestCase {
  override func setUpWithError() throws { continueAfterFailure = false }

  func testWelcomePracticeWrongCutHintPersistenceAndSharing() {
    let app = XCUIApplication()
    app.launchArguments = ["-ui-testing", "-reset-state"]
    app.launch()
    XCTAssertTrue(app.buttons["welcome-next"].waitForExistence(timeout: 10))
    for _ in 0..<3 { app.buttons["welcome-next"].tap() }
    XCTAssertTrue(app.buttons["letter-2"].waitForExistence(timeout: 5))
    app.buttons["letter-1"].tap()
    app.buttons["letter-3"].tap()
    app.buttons["commit-cut"].tap()
    XCTAssertTrue(
      app.otherElements["cut-feedback"].exists || app.staticTexts["cut-feedback"].exists)
    app.buttons["hint-button"].tap()
    app.buttons["letter-2"].tap()
    app.buttons["letter-4"].tap()
    XCTAssertEqual(app.staticTexts["cut-word"].label, "RAT")
    app.terminate()
    app.launchArguments = ["-ui-testing"]
    app.launch()
    XCTAssertTrue(app.buttons["commit-cut"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.staticTexts["cut-word"].label, "RAT")
    app.buttons["commit-cut"].tap()
    app.buttons["commit-cut"].tap()
    cut(app, start: 1, end: 3)
    cut(app, start: 2, end: 4)
    XCTAssertTrue(app.buttons["share-receipt"].waitForExistence(timeout: 5))
    XCTAssertEqual(app.staticTexts["receipt-marks"].label, "2* · 1 · 1")
    app.buttons["share-receipt"].tap()
    XCTAssertTrue(app.buttons["Close"].waitForExistence(timeout: 5) || app.navigationBars.count > 0)
  }

  func testDragRevealAndDaily() {
    let app = XCUIApplication()
    app.launchArguments = ["-ui-testing", "-reset-state", "-capture-screen", "game"]
    app.launch()
    let first = app.buttons["letter-2"]
    let last = app.buttons["letter-4"]
    XCTAssertTrue(first.waitForExistence(timeout: 5))
    first.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).press(
      forDuration: 0.1,
      thenDragTo: last.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
    XCTAssertEqual(app.staticTexts["cut-word"].label, "RAT")
    app.buttons["reveal-button"].tap()
    app.buttons["Reveal answer"].tap()
    app.buttons["commit-cut"].tap()
    cut(app, start: 1, end: 3)
    cut(app, start: 2, end: 4)
    XCTAssertEqual(app.staticTexts["receipt-marks"].label, "— · 1 · 1")
    app.buttons["back-studio"].tap()
    app.buttons["play-daily"].tap()
    XCTAssertTrue(app.buttons["commit-cut"].exists)
    app.buttons["back-studio"].tap()
    app.buttons["tab-2"].tap()
    XCTAssertTrue(
      app.staticTexts["Saved receipts"].exists || app.staticTexts["SAVED RECEIPTS"].exists)
  }

  func testLargeTextAndLongWordCanFinish() {
    let app = XCUIApplication()
    app.launchArguments = [
      "-ui-testing", "-reset-state", "-capture-screen", "practice",
      "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
    ]
    app.launch()
    let pack = app.buttons["pack-little-tricks"]
    XCTAssertTrue(pack.waitForExistence(timeout: 5))
    if !pack.isHittable { app.swipeUp() }
    pack.tap()
    for _ in 0..<3 {
      app.buttons["reveal-button"].tap()
      app.buttons["Reveal answer"].tap()
      app.buttons["commit-cut"].tap()
    }
    XCTAssertTrue(app.buttons["share-receipt"].waitForExistence(timeout: 5))
  }

  func testPracticeReplayKeepsBothReceipts() {
    let app = XCUIApplication()
    app.launchArguments = ["-ui-testing", "-reset-state", "-capture-screen", "receipt"]
    app.launch()
    XCTAssertTrue(app.buttons["share-receipt"].waitForExistence(timeout: 5))
    app.buttons["back-studio"].tap()
    app.buttons["tab-1"].tap()
    app.buttons["pack-first-cuts"].tap()
    cut(app, start: 2, end: 4)
    cut(app, start: 1, end: 3)
    cut(app, start: 2, end: 4)
    app.buttons["back-studio"].tap()
    app.buttons["tab-2"].tap()
    XCTAssertEqual(
      app.staticTexts.matching(NSPredicate(format: "label == %@", "First cuts")).count, 2)
  }

  func testRecordPreview() throws {
    guard ProcessInfo.processInfo.environment["SNIP_RECORD_PREVIEW"] == "1" else {
      throw XCTSkip("Run only for optional App Store recording")
    }
    let app = XCUIApplication()
    app.launchArguments = ["-ui-testing", "-reset-state", "-capture-screen", "game"]
    app.launch()
    XCTAssertTrue(app.buttons["letter-2"].waitForExistence(timeout: 5))
    print("SNIP_VIDEO_BEGIN")
    fflush(stdout)
    Thread.sleep(forTimeInterval: 3)
    app.buttons["letter-2"].tap()
    app.buttons["letter-4"].tap()
    Thread.sleep(forTimeInterval: 2)
    app.buttons["commit-cut"].tap()
    Thread.sleep(forTimeInterval: 2)
    app.buttons["commit-cut"].tap()
    app.buttons["letter-1"].tap()
    app.buttons["letter-3"].tap()
    Thread.sleep(forTimeInterval: 1.5)
    app.buttons["commit-cut"].tap()
    app.buttons["commit-cut"].tap()
    app.buttons["letter-2"].tap()
    app.buttons["letter-4"].tap()
    Thread.sleep(forTimeInterval: 1.5)
    app.buttons["commit-cut"].tap()
    app.buttons["commit-cut"].tap()
    Thread.sleep(forTimeInterval: 3)
    print("SNIP_VIDEO_END")
    fflush(stdout)
  }

  private func cut(_ app: XCUIApplication, start: Int, end: Int) {
    XCTAssertTrue(app.buttons["letter-\(start)"].waitForExistence(timeout: 5))
    app.buttons["letter-\(start)"].tap()
    app.buttons["letter-\(end)"].tap()
    app.buttons["commit-cut"].tap()
    app.buttons["commit-cut"].tap()
  }
}
