import SwiftUI

struct CommandPaletteView: View {
    let items: [CommandPaletteItem]
    let accountForID: (UUID) -> AccountProfile?
    let avatarForAccount: (AccountProfile) -> NSImage?
    let perform: (KeaCommand) -> Void
    let dismiss: () -> Void

    @State private var query = ""
    @State private var selectedItemID: String?
    @FocusState private var isSearchFocused: Bool

    private var filteredItems: [CommandPaletteItem] {
        CommandPaletteCatalog.filtered(items, query: query)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)

                TextField("Search accounts and commands…", text: $query)
                    .textFieldStyle(.plain)
                    .font(.system(size: 16))
                    .focused($isSearchFocused)
                    .onSubmit(activateSelectedItem)
                    .accessibilityLabel("Search accounts and commands")

                Text("esc")
                    .font(.caption.monospaced())
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 5))
            }
            .padding(.horizontal, 16)
            .frame(height: 52)

            Divider()

            if filteredItems.isEmpty {
                ContentUnavailableView.search(text: query)
                    .frame(maxWidth: .infinity, minHeight: 180)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(CommandPaletteSection.allCases, id: \.self) { section in
                                let sectionItems = filteredItems.filter { $0.section == section }
                                if !sectionItems.isEmpty {
                                    Text(section.rawValue.uppercased())
                                        .font(.caption2.weight(.semibold))
                                        .foregroundStyle(.tertiary)
                                        .padding(.horizontal, 12)
                                        .padding(.top, 10)
                                        .padding(.bottom, 2)

                                    ForEach(sectionItems) { item in
                                        CommandPaletteRow(
                                            item: item,
                                            account: account(for: item),
                                            avatar: avatar(for: item),
                                            isSelected: selectedItemID == item.id
                                        ) {
                                            selectedItemID = item.id
                                            activate(item)
                                        } onHover: {
                                            if item.isEnabled {
                                                selectedItemID = item.id
                                            }
                                        }
                                        .id(item.id)
                                    }
                                }
                            }
                        }
                        .padding(6)
                    }
                    .onChange(of: selectedItemID) { _, itemID in
                        guard let itemID else { return }
                        withAnimation(.easeOut(duration: 0.1)) {
                            proxy.scrollTo(itemID, anchor: .center)
                        }
                    }
                }
                .frame(maxHeight: 390)
            }
        }
        .frame(width: 560)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(.primary.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.28), radius: 28, y: 12)
        .onAppear {
            selectFirstEnabledItem()
            isSearchFocused = true
        }
        .onChange(of: query) {
            selectFirstEnabledItem()
        }
        .onExitCommand(perform: dismiss)
        .onKeyPress(.downArrow) {
            moveSelection(by: 1)
            return .handled
        }
        .onKeyPress(.upArrow) {
            moveSelection(by: -1)
            return .handled
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Kea command palette")
    }

    private func account(for item: CommandPaletteItem) -> AccountProfile? {
        guard case .selectAccount(let id) = item.command else { return nil }
        return accountForID(id)
    }

    private func avatar(for item: CommandPaletteItem) -> NSImage? {
        guard let account = account(for: item) else { return nil }
        return avatarForAccount(account)
    }

    private func selectFirstEnabledItem() {
        selectedItemID = filteredItems.first(where: \.isEnabled)?.id
    }

    private func moveSelection(by offset: Int) {
        let enabledItems = filteredItems.filter(\.isEnabled)
        guard !enabledItems.isEmpty else { return }
        let currentIndex = selectedItemID.flatMap { id in enabledItems.firstIndex { $0.id == id } } ?? 0
        let nextIndex = (currentIndex + offset + enabledItems.count) % enabledItems.count
        selectedItemID = enabledItems[nextIndex].id
    }

    private func activateSelectedItem() {
        guard let item = filteredItems.first(where: { $0.id == selectedItemID }) else { return }
        activate(item)
    }

    private func activate(_ item: CommandPaletteItem) {
        guard item.isEnabled else { return }
        perform(item.command)
    }
}

private struct CommandPaletteRow: View {
    let item: CommandPaletteItem
    let account: AccountProfile?
    let avatar: NSImage?
    let isSelected: Bool
    let activate: () -> Void
    let onHover: () -> Void

    var body: some View {
        Button(action: activate) {
            HStack(spacing: 10) {
                if let account {
                    AccountAvatarView(account: account, avatar: avatar, size: 26)
                } else {
                    Image(systemName: item.systemImage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 26, height: 26)
                }

                Text(item.title)
                    .lineLimit(1)
                Spacer()
                if let shortcutHint = item.shortcutHint {
                    Text(shortcutHint)
                        .font(.callout.monospaced())
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 10)
            .frame(height: 38)
            .background(
                isSelected ? Color.accentColor.opacity(0.14) : .clear,
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!item.isEnabled)
        .opacity(item.isEnabled ? 1 : 0.45)
        .onHover { hovering in
            if hovering { onHover() }
        }
        .accessibilityLabel(item.title)
        .accessibilityValue(item.shortcutHint ?? "")
    }
}
