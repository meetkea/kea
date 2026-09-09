# Kea privacy

Kea is designed to keep account handling local and simple.

- Kea has no backend.
- Kea includes no telemetry, analytics, or crash-reporting SDK.
- Kea does not use the X API.
- Kea application code never asks for, reads, or stores X usernames, passwords, access tokens, or session cookies.
- Kea does not enumerate passkeys or store passkey identifiers, verification codes, or authentication challenge payloads.
- Sign-in happens directly on x.com inside Apple's WebKit.
- Password AutoFill, passkeys, Touch ID, credential-manager UI, and verification-code suggestions remain owned by WebKit and macOS AuthenticationServices where supported.
- Each account's cookies and website data are managed by a separate persistent WebKit data store on the Mac.
- SwiftData contains only local Kea metadata such as the account label, accent/avatar identifiers, and browser-profile UUID.
- Optional custom avatars are user-selected, normalized to a local Kea-owned copy, and never fetched or inferred from X.
- Kea does not scrape X pages to identify accounts or collect profile content.
- The optional hidden-sidebar layout applies static local CSS selectors. It does not read, collect, or transmit X page content.
- User-activated external links may open in the Mac's default browser when that preference is enabled.
- Kea writes privacy-preserving lifecycle diagnostics to Apple's local unified log without account labels, complete URLs, headers, cookies, credentials, or website storage.

Clearing a session deletes that account's WebKit website data while keeping its local metadata. Removing an account deletes its Kea-owned avatar copy, local metadata, and isolated WebKit session without touching the user's original image.
