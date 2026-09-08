import SwiftUI

struct AccountItemView: View {
    let account: AccountProfile
    let isSelected: Bool

    private var initial: String {
        String(account.name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1)).uppercased()
    }

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.15) : .clear)

            if isSelected {
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: 3, height: 24)
                    .offset(x: -1)
            }

            Text(initial.isEmpty ? "?" : initial)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
                .frame(width: 34, height: 34)
                .background(Color(nsColor: .controlBackgroundColor), in: Circle())
                .overlay {
                    Circle()
                        .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.25), lineWidth: isSelected ? 2 : 1)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 48, height: 48)
        .contentShape(Rectangle())
        .accessibilityLabel(account.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
