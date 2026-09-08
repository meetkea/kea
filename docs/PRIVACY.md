# Kea privacy

Kea is designed to keep account handling local and simple.

- Kea has no backend.
- Kea includes no telemetry, analytics, or crash-reporting SDK.
- Kea does not use the X API.
- Kea application code never asks for, reads, or stores X usernames, passwords, access tokens, or session cookies.
- Sign-in happens directly on x.com inside Apple's WebKit.
- Each account's cookies and website data are managed by a separate persistent WebKit data store on the Mac.
- SwiftData contains only local Kea metadata such as the account label and browser-profile UUID.
- Kea does not scrape X pages to identify accounts or collect profile content.
- User-activated external links may open in the Mac's default browser when that preference is enabled.
- Kea writes privacy-preserving lifecycle diagnostics to Apple's local unified log without account labels, complete URLs, headers, cookies, credentials, or website storage.

Clearing a session deletes that account's WebKit website data while keeping its local label. Removing an account deletes both its local label and isolated WebKit session.
