import AppKit
import SwiftUI

struct AccountAvatarView: View {
    let account: AccountProfile
    let avatar: NSImage?
    var size: CGFloat = 34
    var isSelected = false

    private var accent: AccountAccent {
        AccountAccent.selection(for: account.accentIdentifier)
    }

    private var initial: String {
        String(account.name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1)).uppercased()
    }

    var body: some View {
        Group {
            if let avatar {
                Image(nsImage: avatar)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(initial.isEmpty ? "?" : initial)
                    .font(.system(size: size * 0.44, weight: .semibold, design: .rounded))
                    .foregroundStyle(isSelected ? accent.color : Color.primary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(nsColor: .controlBackgroundColor))
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .overlay {
            Circle()
                .stroke(
                    isSelected ? accent.color : Color.secondary.opacity(0.22),
                    lineWidth: isSelected ? 2 : 1
                )
        }
        .accessibilityHidden(true)
    }
}
