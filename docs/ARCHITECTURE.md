# Kea architecture

## Account metadata

`AccountProfile` is a SwiftData model containing only Kea-owned metadata: a local label, ordering, timestamps, a safe last X URL, and a unique browser data-store identifier. It never contains an X username, password, token, cookie, or scraped profile data.

## Isolated browser profiles

Each account gets a unique UUID at creation. `AccountSessionManager` creates a persistent `WKWebsiteDataStore` with `WKWebsiteDataStore(forIdentifier:)`. `WebViewPool` assigns that store to `WKWebViewConfiguration.websiteDataStore` before constructing the account's web view. The default global data store is never used for an account.

Because the stores are identifier-backed and persistent, cookies, local storage, caches, and X authentication survive app relaunch while remaining separate between accounts.

## WebViewPool lifecycle and switching

`WebViewPool` lazily creates one `BrowserSession` per account and retains it for the lifetime of the app process. Switching changes which retained `WKWebView` is attached to the SwiftUI/AppKit host. It does not recreate or reload the view, so the active page and scroll position remain intact.

The coordinator tracks loading, navigation state, safe URL changes, file inputs, new-window requests, load failures, and content-process termination. WebKit and its delegates remain on the main actor.

## Session deletion

Clear Session and Remove Account first detach and release the account's `WKWebView`. Only then does Kea await `WKWebsiteDataStore.remove(forIdentifier:)`. Clear Session keeps the SwiftData record and creates a fresh store on next display. Remove Account deletes the SwiftData record only after WebKit confirms that store deletion succeeded.

## Persistence boundary

SwiftData stores Kea metadata. `UserDefaults` stores lightweight preferences and the selected account UUID. WebKit alone stores X website data. A last URL is persisted only when it is HTTPS on an X-owned host, is outside sensitive login/security paths, and has its query and fragment removed.

## Why Kea does not use the X API

The MVP's purpose is native management of multiple isolated sessions around the existing X website. X owns the timeline and posting interface. Adding an API client or replacement timeline would create a different product, add credential and policy complexity, and break this ownership boundary.
