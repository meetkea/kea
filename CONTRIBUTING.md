# Contributing to Kea

Thanks for helping improve Kea. Focused bug fixes, accessibility improvements, tests, documentation, and small macOS UX refinements are welcome.

## Before you start

- Keep Kea native: Swift 6, SwiftUI, SwiftData, WebKit, and AppKit only where required.
- Preserve one persistent, isolated `WKWebsiteDataStore` per account.
- Do not add an X API client, backend, credential storage, DOM scraping, analytics, or telemetry.
- Discuss broad product changes in an issue before implementation.

## Development

Open `Kea.xcodeproj` with Xcode 26 or later. Kea targets macOS 15 or later and has no third-party dependencies.

Before submitting a pull request, run:

```sh
xcodebuild -project Kea.xcodeproj -scheme Kea -destination 'platform=macOS' build
xcodebuild -project Kea.xcodeproj -scheme Kea -destination 'platform=macOS' test
```

Tests must not depend on live x.com responses or real account credentials. Explain any manual X flows you verified and keep unrelated changes out of the pull request.
