# Authentication in Kea

Kea delegates authentication to X, Apple's WebKit, and macOS AuthenticationServices. It does not provide credential fields, inject login JavaScript, inspect the X DOM, intercept authentication challenge payloads, enumerate credentials, or store passwords, passkeys, verification codes, cookies, or tokens in Kea-owned storage.

## Passwords, verification codes, and Touch ID

The X login experience runs inside the selected account's `WKWebView`. Apple documents that WebKit automatically handles web authentication challenges and presents system credential UI where supported. This preserves Apple Passwords, third-party credential managers, password AutoFill, verification-code suggestions, and Touch ID without giving Kea access to the credential values.

Kea provides **Open Passwords…** directly above recognized X login pages and in the Help menu, account context menu, and Sign-In settings. It resolves the public `com.apple.Passwords` bundle identifier with `NSWorkspace` and starts a foreground UI instance; this avoids reusing Passwords' background helper, which has no visible window. Kea never reads data from Passwords. Opening Passwords is an explicit fallback for selecting or copying a credential; Kea cannot force the system AutoFill suggestion to appear inside an X-owned HTML field.

## Passkey access

On launch, Kea reads `authorizationStateForPlatformCredentials` from `ASAuthorizationWebBrowserPublicKeyCredentialManager`. If the state is `notDetermined`, the Sign-In settings and Help menu provide a user-initiated **Allow Passkey Access…** action. Kea calls the system permission API only from that action. If access is denied, Kea does not ask again. It never calls `platformCredentials(forRelyingParty:)` or presents a custom credential picker, so credential metadata remains outside Kea.

Passkey authorization is system-wide, but X website state remains account-specific: each account still has its own persistent `WKWebsiteDataStore`, configured before that account's `WKWebView` is created.

## Apple platform limitations

Passkey availability in an embedded web view is controlled by X, WebKit, macOS, the user's credential providers, and Apple signing capabilities. Apple documents two relevant paths:

- An app using passkeys for a service it owns configures that service as an associated `webcredentials` domain. Kea does not own `x.com`, so it cannot establish that association.
- A general web browser can request Apple's managed `com.apple.developer.web-browser.public-key-credential` entitlement for arbitrary relying parties. Apple restricts this entitlement to qualifying browser apps and reviews requests. Kea is an X-focused client, not a general-purpose browser, and does not declare an unapproved restricted entitlement.

Consequently, Kea preserves and requests the system passkey flow where the installed macOS/WebKit environment makes it available, but the project cannot guarantee X passkey support on every signed build or Mac. It does not replace an unavailable system flow with credential handling of its own.

## Manual validation

Unit tests cannot use real credentials or depend on live x.com behavior. Before release, validate password AutoFill, an X passkey, Touch ID, verification codes or two-factor authentication, and two different account profiles using dedicated test accounts. Confirm that cookies and authenticated state never cross between the two profiles.
