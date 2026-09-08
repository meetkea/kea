# Kea contributor guidance

- Keep the deployment target at macOS 15+ and use Swift 6, SwiftUI, SwiftData, and WebKit.
- Preserve the account-isolation invariant: every account uses `WKWebsiteDataStore(forIdentifier:)` with its own UUID, assigned before its `WKWebView` is created.
- Release all web views that use a persistent store before calling `WKWebsiteDataStore.remove(forIdentifier:)`.
- Do not add an X API client, backend, credential storage, DOM scraping, analytics, or telemetry.
- Do not replace the supplied `AppIcon`, `KeaMark`, or `KeaLogo` artwork.
- Keep WebKit and UI services MainActor-bound and maintain strict Swift 6 concurrency checks.
- Serialize destructive session operations per account and keep authentication navigation in the account context without provider hostname allowlists.
- Use OSLog only and never log account labels, complete URLs, cookies, headers, credentials, or website storage.
- Leave passwords, passkeys, Touch ID, verification codes, and authentication challenges to WebKit and AuthenticationServices. Never inspect login fields or enumerate credentials.
- Avoid third-party dependencies unless a concrete requirement cannot be met with Apple frameworks.
- Run the macOS build and unit tests before submitting changes. Tests must not rely on live x.com responses.
