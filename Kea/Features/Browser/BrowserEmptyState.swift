import SwiftUI

struct BrowserEmptyState: View {
    let addAccount: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Image("KeaMark")
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .accessibilityHidden(true)

            VStack(spacing: 6) {
                Text("Kea")
                    .font(.system(size: 30, weight: .semibold))
                Text("Add your first X account.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Button("Add Account", action: addAccount)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}
