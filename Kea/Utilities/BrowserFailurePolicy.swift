import Foundation

enum BrowserFailurePolicy {
    nonisolated private static let connectivityCodes: Set<Int> = [
        NSURLErrorTimedOut,
        NSURLErrorCannotFindHost,
        NSURLErrorCannotConnectToHost,
        NSURLErrorNetworkConnectionLost,
        NSURLErrorDNSLookupFailed,
        NSURLErrorNotConnectedToInternet,
        NSURLErrorInternationalRoamingOff,
        NSURLErrorDataNotAllowed,
        NSURLErrorSecureConnectionFailed
    ]

    nonisolated static func shouldShowNativeOverlay(for error: NSError) -> Bool {
        error.domain == NSURLErrorDomain && connectivityCodes.contains(error.code)
    }
}
