import AppKit
import SwiftUI

struct AccountItemView: View {
    let account: AccountProfile
    let avatar: NSImage?
    let isSelected: Bool
    @State private var isHovering = false

    private var accent: AccountAccent {
        AccountAccent.selection(for: account.accentIdentifier)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(backgroundColor)

            AccountAvatarView(
                account: account,
                avatar: avatar,
                isSelected: isSelected
            )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 46, height: 46)
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovering)
        .accessibilityLabel(account.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var backgroundColor: Color {
        if isSelected {
            return accent.color.opacity(isHovering ? 0.17 : 0.13)
        }
        return isHovering ? Color.primary.opacity(0.06) : .clear
    }
}
