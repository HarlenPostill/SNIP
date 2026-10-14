# SNIP native iOS app

SNIP is a SwiftUI word game for iPhone on iOS 18 or later. Select a continuous word from inside another word; the removed piece and remaining letters answer two clues. The app includes 90 daily puzzles on a 30-day UTC rotation, 12 practice puzzles, local saved progress, scored hints/reveals, daily streaks, image/text sharing, optional local reminders, sound, and haptics.

Open `sol-word-test.xcodeproj`, choose the shared **SNIP** scheme, and run on an iPhone simulator or signed device. The internal target remains `sol-word-test`; the installed display name is SNIP. The bundle identifier is `com.hrln-interactive.snip`.

## Content and verification

`work/puzzles.tsv` is the original editorial source. `python3 scripts/compile_content.py` validates each extraction and compiles `sol-word-test/Puzzles.json`. The first 90 daily rows ship; remaining draft rows are retained for future content. Practice collections use separate source words.

Run the Foundation engine checks:

```sh
swiftc sol-word-test/GameEngine.swift tests/EngineChecks.swift -o work/engine-checks
work/engine-checks sol-word-test/Puzzles.json
```

Run the native UI suite with Xcode's Test action, or:

```sh
xcodebuild -project sol-word-test.xcodeproj -scheme SNIP -destination 'platform=iOS Simulator,name=iPhone 16 Pro,OS=18.6' -parallel-testing-enabled NO test
```

UI tests cover introduction, wrong cuts, hints, drag selection, reveals, saved selection after relaunch, completing practice, sharing, daily navigation, and large text. Debug-only `-ui-testing` uses an isolated defaults suite; `-reset-state` clears only that suite. Debug-only `-capture-screen` uses genuine practice data for reproducible images. These arguments do not exist in Release builds.

The native app has no package dependencies. Artwork scripts use Python with Pillow, macOS's installed Georgia/Helvetica/Courier fonts, and FFmpeg for the optional video. `scripts/capture_screens.py` captures the built app; `scripts/make_store_assets.py` composes campaign images; `scripts/record_preview.py` records a dedicated native UI workflow. Each script's simulator ID can be changed for another installed device.

## Submission package

`appstore/` contains listing metadata, screenshot sets, header/search creatives, the icon, raw captures, optional preview video, and static companion website pages. `appstore/metadata/submission-guide.txt` explains which assets and fields go where, cites Apple's specifications, and lists account-level steps remaining before upload.

The website is staged locally for `snip.hrln-interactive.com`; it has not been deployed. The app has no networking dependency. Sharing uses the system share sheet and never sends automatically. Notifications are local and request permission only after the user enables them.

Progress and preferences use app-local UserDefaults. The privacy manifest declares reason CA92.1. There are no external libraries, analytics, advertisements, or purchases.

2026 HRLN interactive
