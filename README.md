<p align="center">
  <img src="Kea/Resources/Assets.xcassets/KeaLogo.imageset/KeaLogo.png" alt="Kea" width="420">
</p>

<h1 align="center">Kea</h1>

<p align="center"><strong>App for X on Mac.</strong></p>

Kea is a free, open-source, native multi-account client for X on macOS. It keeps every account in a separate persistent WebKit session, so you can sign in once, switch instantly, and manage personal, work, company, or community accounts from one place.

> X owns the X interface. Kea owns the Mac experience.

## Features

- Separate persistent cookies and website data for every account
- Instant account switching without reloading or losing scroll position
- Native macOS account rail, menus, keyboard shortcuts, and settings
- Back, Forward, Reload, page zoom, external links, and media file selection
- Local account labels with rename, Clear Session, and Remove Account actions
- System, Light, and Dark appearance
- No X API, backend, telemetry, analytics, or third-party dependencies

## Status

Kea is an early macOS MVP. The native application foundation and core multi-account workflow are implemented. Distribution, signing, and release packaging are not finalized.

## Requirements

- macOS 15.0 or later
- Xcode 26 or later
- Swift 6

## Build locally

1. Clone [github.com/meetkea/kea](https://github.com/meetkea/kea).
2. Open `Kea.xcodeproj` in Xcode.
3. Select the `Kea` scheme and the `My Mac` destination.
4. Choose **Product > Run**.

From Terminal:

```sh
xcodebuild -project Kea.xcodeproj -scheme Kea -destination 'platform=macOS' build
xcodebuild -project Kea.xcodeproj -scheme Kea -destination 'platform=macOS' test
```

The app target uses App Sandbox with outgoing network access and user-selected read-only file access for X media uploads.

## Architecture

Kea uses SwiftUI, SwiftData, and a wrapped `WKWebView`. Every local `AccountProfile` owns a unique persistent `WKWebsiteDataStore` identifier. `WebViewPool` retains one loaded web view per account while the app runs, preserving the page and scroll position during switching. See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Privacy

Kea has no backend, telemetry, or analytics. It does not use the X API and never asks for or stores an X password. Authentication and website data remain in WebKit on the Mac. See [docs/PRIVACY.md](docs/PRIVACY.md).

## Contributing

Issues and focused pull requests are welcome. Keep the app native, dependency-light, and within the ownership boundary: X owns the website interface; Kea owns the Mac account-switching experience.

Before opening a pull request, run both the macOS build and unit tests shown above. Tests must not depend on live x.com responses.

## Links

- [Kea website](https://usekea.com)
- [Support Kea](https://usekea.com/support)
- [Architecture](docs/ARCHITECTURE.md)
- [Privacy](docs/PRIVACY.md)
