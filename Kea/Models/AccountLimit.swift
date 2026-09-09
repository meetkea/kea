import Foundation

enum AccountLimit {
    static let maximumAccountCount = 5
    static let alertTitle = "Account limit reached"
    static var alertMessage: String {
        "Kea currently supports up to \(maximumAccountCount) accounts to keep switching fast and memory usage predictable."
    }

    static var helpText: String {
        "Maximum \(maximumAccountCount) accounts"
    }

    static func allowsAddingAccount(currentCount: Int) -> Bool {
        currentCount < maximumAccountCount
    }
}
