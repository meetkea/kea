import SwiftUI

struct AccountEditorView: View {
    let title: String
    let actionTitle: String
    let initialName: String
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @FocusState private var isNameFocused: Bool

    init(
        title: String,
        actionTitle: String,
        initialName: String = "",
        onSave: @escaping (String) -> Void
    ) {
        self.title = title
        self.actionTitle = actionTitle
        self.initialName = initialName
        self.onSave = onSave
        _name = State(initialValue: initialName)
    }

    private var cleanedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(title)
                .font(.title2.weight(.semibold))

            VStack(alignment: .leading, spacing: 6) {
                Text("Local label")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                TextField("Personal", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .focused($isNameFocused)
                    .onSubmit(save)
            }

            Text("This name stays on your Mac. Sign-in happens directly on x.com.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button(actionTitle, action: save)
                    .keyboardShortcut(.defaultAction)
                    .disabled(cleanedName.isEmpty)
            }
        }
        .padding(24)
        .frame(width: 390)
        .onAppear { isNameFocused = true }
    }

    private func save() {
        guard !cleanedName.isEmpty else { return }
        onSave(cleanedName)
        dismiss()
    }
}
