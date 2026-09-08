import AppKit
import AuthenticationServices
import Observation

nonisolated enum PasskeyAccessStatus: Equatable, Sendable {
    case authorized
    case denied
    case notDetermined
}

nonisolated enum PasskeyAccessPolicy {
    static func canRequestAccess(status: PasskeyAccessStatus, isRequesting: Bool) -> Bool {
        status == .notDetermined && !isRequesting
    }
}

@MainActor
@Observable
final class AuthenticationAccessService {
    private(set) var passkeyStatus: PasskeyAccessStatus
    private(set) var isRequestingPasskeyAccess = false

    @ObservationIgnored
    private let credentialManager: ASAuthorizationWebBrowserPublicKeyCredentialManager

    init(credentialManager: ASAuthorizationWebBrowserPublicKeyCredentialManager = .init()) {
        self.credentialManager = credentialManager
        passkeyStatus = Self.status(from: credentialManager.authorizationStateForPlatformCredentials)
    }

    var canRequestPasskeyAccess: Bool {
        PasskeyAccessPolicy.canRequestAccess(
            status: passkeyStatus,
            isRequesting: isRequestingPasskeyAccess
        )
    }

    var passkeyStatusTitle: String {
        switch passkeyStatus {
        case .authorized: "Allowed"
        case .denied: "Not Allowed"
        case .notDetermined: "Not Requested"
        }
    }

    var passkeyStatusDescription: String {
        switch passkeyStatus {
        case .authorized:
            "macOS allows Kea to use system passkey UI when X and WebKit support it."
        case .denied:
            "macOS denied access. Kea will not ask again. You can change this in System Settings > Privacy & Security > Passkeys Access for Web Browsers."
        case .notDetermined:
            "Allow macOS to offer passkeys from Apple Passwords and supported credential managers when X requests one."
        }
    }

    func refreshPasskeyStatus() {
        passkeyStatus = Self.status(from: credentialManager.authorizationStateForPlatformCredentials)
    }

    func requestPasskeyAccess() async {
        refreshPasskeyStatus()
        guard canRequestPasskeyAccess else { return }

        isRequestingPasskeyAccess = true
        defer { isRequestingPasskeyAccess = false }

        let authorizationState = await withCheckedContinuation { continuation in
            credentialManager.requestAuthorizationForPublicKeyCredentials { state in
                continuation.resume(returning: state)
            }
        }
        passkeyStatus = Self.status(from: authorizationState)
        KeaLogger.app.info("A user-initiated system passkey access request completed")
    }

    func openPasswords() async {
        guard let applicationURL = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: "com.apple.Passwords"
        ) else {
            showPasswordsUnavailableAlert()
            return
        }

        do {
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            // Passwords can leave a background helper registered with the same
            // bundle identifier. A fresh UI instance reliably presents its window.
            configuration.createsNewApplicationInstance = true
            let application = try await NSWorkspace.shared.openApplication(
                at: applicationURL,
                configuration: configuration
            )
            guard application.activate(options: [.activateAllWindows]) else {
                showPasswordsUnavailableAlert()
                return
            }
            KeaLogger.app.info("Opened the system Passwords application at the user's request")
        } catch {
            showPasswordsUnavailableAlert()
        }
    }

    private static func status(
        from state: ASAuthorizationWebBrowserPublicKeyCredentialManager.AuthorizationState
    ) -> PasskeyAccessStatus {
        switch state {
        case .authorized: .authorized
        case .denied: .denied
        case .notDetermined: .notDetermined
        @unknown default: .denied
        }
    }

    private func showPasswordsUnavailableAlert() {
        KeaLogger.app.error("The system Passwords application could not be opened")
        let alert = NSAlert()
        alert.messageText = "Passwords Could Not Be Opened"
        alert.informativeText = "Open the Passwords app from Applications or System Settings and try again."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
