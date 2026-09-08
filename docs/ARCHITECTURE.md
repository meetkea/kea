# Kea architecture

## Account metadata

`AccountProfile` is a SwiftData model containing only Kea-owned metadata: a local label, ordering, timestamps, a safe last X URL, and a unique browser data-store identifier. It never contains an X username, password, token, cookie, or scraped profile data.

## Isolated browser profiles

Each account gets a unique UUID at creation. `AccountSessionManager` creates a persistent `WKWebsiteDataStore` with `WKWebsiteDataStore(forIdentifier:)`. `WebViewPool` assigns that store to `WKWebViewConfiguration.websiteDataStore` before constructing the account's web view. The default global data store is never used for an account.

Because the stores are identifier-backed and persistent, cookies, local storage, caches, and X authentication survive app relaunch while remaining separate between accounts.

## WebViewPool lifecycle and switching

`WebViewPool` lazily creates one `BrowserSession` per account and retains it for the lifetime of the app process. Switching changes which retained `WKWebView` is attached to the SwiftUI/AppKit host. It does not recreate or reload the view, so the active page and scroll position remain intact.

The coordinator tracks loading, navigation state, safe URL changes, file inputs, new-window requests, load failures, and content-process termination. WebKit and its delegates remain on the main actor.

Loaded views are intentionally retained for instant switching; eviction is not part of the alpha. The main-actor dictionary is the single creation gate, so one loaded view exists per account. `WKWebView` holds its delegates weakly, while `BrowserSession` retains its coordinator; coordinator callbacks capture application state and account models weakly, avoiding a retain cycle. The SwiftUI bridge also keeps only a weak reference to the web view, making the pool its sole long-lived owner.

If one WebKit content process terminates, its coordinator reloads only that account's existing view with the same isolated data store. It does not recreate every account or delete website data.

## Session deletion

Clear Session and Remove Account are serialized per account. SwiftUI first replaces the browser with a transition state, and `WebViewPool` stops loading, clears delegates, detaches, and releases the view. Only then does Kea await `WKWebsiteDataStore.remove(forIdentifier:)`.

Clear Session keeps the SwiftData record, clears the safe last URL, immediately creates a fresh store with the same profile identifier, and loads `x.com/home`. Remove Account deletes the SwiftData record only after WebKit confirms store deletion. If store deletion fails, metadata remains and Kea reconstructs the account view. Repeated operations for the same account are ignored while one is in progress.

## Navigation and new windows

Normal X navigation and non-user-initiated redirects remain inside the account's isolated view. A user-activated HTTP(S) link from a normal X content page to another site opens in the default browser when that preference is enabled. Authentication is kept in-app based on navigation context rather than a fixed provider hostname list, so X can change identity providers without requiring a Kea update.

For `target="_blank"`, Kea either opens a deliberate external destination in the default browser or loads the request in the current account view. It never creates a hidden or default-store `WKWebView`.

The native `NSOpenPanel` used for HTML file inputs returns only user-selected URLs and retains no persistent file access. The sandbox's user-selected read-only entitlement is sufficient because uploads only read the chosen media.

## Authentication services

WebKit owns X password, passkey, Touch ID, and two-factor authentication UI. Kea does not implement `WKNavigationDelegate` authentication-challenge handling or inject login JavaScript. `AuthenticationAccessService` reads and, only after an explicit user action, requests the system passkey authorization state through `ASAuthorizationWebBrowserPublicKeyCredentialManager`. It does not enumerate platform credentials or receive credential responses.

The same service resolves and opens the Passwords application by its public bundle identifier using `NSWorkspace`. This is a convenience action only; Kea has no Passwords or Keychain data access. Platform and entitlement limitations are documented in [AUTHENTICATION.md](AUTHENTICATION.md).

## Persistence boundary

SwiftData stores Kea metadata. `UserDefaults` stores lightweight preferences and the selected account UUID. WebKit alone stores X website data. A last URL is persisted only when it is HTTPS on an X-owned host, is outside login, callback, account-security, and password-reset paths, and contains no recognized temporary credential parameter. Safe query strings and fragments are removed before persistence.

Kea uses local unified logging with `app`, `accounts`, `webview`, and `sessions` categories. Logs describe lifecycle events and numeric network error codes only; they do not include account labels, complete URLs, headers, cookies, credentials, or website storage.

## Why Kea does not use the X API

The MVP's purpose is native management of multiple isolated sessions around the existing X website. X owns the timeline and posting interface. Adding an API client or replacement timeline would create a different product, add credential and policy complexity, and break this ownership boundary.
