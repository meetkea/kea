import SwiftUI

struct AccountItemView: View {
    let account: AccountProfile
    let isSelected: Bool
    @State private var isHovering = false

    private var initial: String {
        String(account.name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1)).uppercased()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(backgroundColor)

            Text(initial.isEmpty ? "?" : initial)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
                .frame(width: 34, height: 34)
                .background(Color(nsColor: .controlBackgroundColor), in: Circle())
                .overlay {
                    Circle()
                        .stroke(
                            isSelected ? Color.accentColor : Color.secondary.opacity(0.22),
                            lineWidth: isSelected ? 2 : 1
                        )
                }
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
            return Color.accentColor.opacity(isHovering ? 0.17 : 0.13)
        }
        return isHovering ? Color.primary.opacity(0.06) : .clear
    }
}
