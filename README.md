# Kea

**App for X on Mac.**

Kea is a free, open-source, native multi-account client for X on macOS.

Stay signed in to multiple X accounts, switch between them instantly, and keep every account completely separate.

<p align="center">
  <img src="Kea/Resources/Assets.xcassets/KeaLogo.imageset/KeaLogo.png" alt="Kea" width="420">
</p>

> X owns the X interface. Kea owns the Mac experience.

## Features

- Separate persistent cookies and website data for every account
- Instant account switching without reloading or losing scroll position
- Native macOS account rail, menus, keyboard shortcuts, and settings
- Back, Forward, Reload, page zoom, external links, and media file selection
- System-owned password, passkey, Touch ID, and verification-code flows where macOS and WebKit support them
- Native access to the Apple Passwords app without reading credentials
- Local account labels with rename, Clear Session, and Remove Account actions
- System, Light, and Dark appearance
- No X API, backend, telemetry, analytics, or third-party dependencies

## Status

Kea is preparing for an early public alpha. The core multi-account workflow is implemented and hardened, but signing, distribution, and manual end-to-end validation with multiple live X accounts are still in progress.

Kea is an independent open-source project and is not affiliated with X.

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

Kea has no backend, telemetry, or analytics. It does not use the X API and never asks for or stores X credentials. Authentication and website data remain in WebKit and macOS system services on the Mac. See [docs/PRIVACY.md](docs/PRIVACY.md) and [docs/AUTHENTICATION.md](docs/AUTHENTICATION.md).

## Contributing

Issues and focused pull requests are welcome. Keep the app native, dependency-light, and within the ownership boundary: X owns the website interface; Kea owns the Mac account-switching experience.

Before opening a pull request, run both the macOS build and unit tests shown above. Tests must not depend on live x.com responses.

See [CONTRIBUTING.md](CONTRIBUTING.md), [SECURITY.md](SECURITY.md), and [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## License

Kea is available under the [MIT License](LICENSE).

## Links

- [Kea website](https://usekea.com)
- [Support Kea](https://usekea.com/support)
- [Architecture](docs/ARCHITECTURE.md)
- [Authentication](docs/AUTHENTICATION.md)
- [Privacy](docs/PRIVACY.md)
