import Foundation
import OSLog

enum KeaLogger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.usekea.Kea"

    static let app = Logger(subsystem: subsystem, category: "app")
    static let accounts = Logger(subsystem: subsystem, category: "accounts")
    static let webView = Logger(subsystem: subsystem, category: "webview")
    static let sessions = Logger(subsystem: subsystem, category: "sessions")
}
