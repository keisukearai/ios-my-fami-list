import SwiftUI

struct ListDetailView: View {
    @State private var list: ShoppingListBrief
    let groupId: Int
    let groupColor: Color
    let groupName: String

    @Environment(\.dismiss) private var dismiss
    @Environment(GroupViewModel.self) private var groupVM
    @Environment(NetworkMonitor.self) private var networkMonitor
    @State private var itemVM: ItemViewModel
    @State private var checkedExpanded = true
    @State private var editingItem: Item?
    @State private var showClearConfirm = false
    @State private var showRenameAlert = false
    @State private var renameText = ""
    @State private var composerText = ""
    @State private var selectedCategory = ""
    @FocusState private var composerFocused: Bool

    init(list: ShoppingListBrief, groupId: Int, groupColor: Color, groupName: String = "") {
        _list = State(initialValue: list)
        self.groupId = groupId
        self.groupColor = groupColor
        self.groupName = groupName
        _itemVM = State(initialValue: ItemViewModel(groupId: groupId, listId: list.id))
    }

    var allCategories: [(key: String, name: String, color: Color)] {
        AppTheme.categories + groupVM.customCategories.map { (key: $0.name, name: $0.name, color: Color(hex: $0.color)) }
    }

    var body: some View {
        VStack(spacing: 0) {
            AppHeader(list.name, onBack: { dismiss() }, right: {
                HStack(spacing: 8) {
                    if !networkMonitor.isConnected {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.textTer)
                    }
                    ellipsisMenu
                }
            })

            ZStack(alignment: .bottom) {
                itemsScrollView
                composerBar
            }
            .background(AppTheme.bg)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $editingItem) { item in
            ItemDetailEditSheet(itemVM: itemVM, item: item, groupColor: groupColor, customCategories: groupVM.customCategories)
        }
        .confirmationDialog(
            loc("Delete all checked items?"),
            isPresented: $showClearConfirm,
            titleVisibility: .visible
        ) {
            Button(loc("Delete"), role: .destructive) {
                Task { await itemVM.clearCheckedItems() }
            }
        }
        .alert(loc("Rename List"), isPresented: $showRenameAlert) {
            TextField(loc("List name"), text: $renameText)
            Button(loc("Save")) {
                let name = renameText.trimmingCharacters(in: .whitespaces)
                guard !name.isEmpty else { return }
                Task {
                    await groupVM.updateList(list, name: name)
                    if let updated = groupVM.currentGroup?.lists.first(where: { $0.id == list.id }) {
                        list = updated
                    }
                }
            }
            Button(loc("Cancel"), role: .cancel) {}
        }
        .alert(loc("Error"), isPresented: Binding(
            get: { itemVM.errorMessage != nil },
            set: { if !$0 { itemVM.errorMessage = nil } }
        )) {
            Button(loc("OK")) { itemVM.errorMessage = nil }
        } message: {
            Text(itemVM.errorMessage ?? "")
        }
        .task { itemVM.start() }
        .onDisappear { itemVM.stop() }
    }

    private var ellipsisMenu: some View {
        Menu {
            Button {
                renameText = list.name
                showRenameAlert = true
            } label: {
                Label(loc("Rename List"), systemImage: "pencil")
            }
            if !itemVM.checkedItems.isEmpty {
                Button(role: .destructive) {
                    showClearConfirm = true
                } label: {
                    Label(loc("Clear Checked Items"), systemImage: "checkmark.circle")
                }
            }
            if groupVM.currentGroup?.isOwner == true {
                Button(role: .destructive) {
                    Task { await groupVM.deleteList(list); dismiss() }
                } label: {
                    Label(loc("Delete List"), systemImage: "trash")
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(AppTheme.surface)
                    .frame(width: 34, height: 34)
                    .shadow(color: AppTheme.sep, radius: 4)
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.text)
            }
        }
    }

    private var itemsScrollView: some View {
        List {
            Section {
                ForEach(itemVM.uncheckedItems) { item in
                    ItemRowView(
                        item: item,
                        groupColor: groupColor,
                        onCheck: { Task { await itemVM.toggleCheck(item) } },
                        onTap: { editingItem = item }
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(AppTheme.surface)
                    .listRowSeparatorTint(AppTheme.hairline)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            Task { await itemVM.deleteItem(item) }
                        } label: {
                            Label(loc("Delete"), systemImage: "trash")
                        }
                    }
                }

                if itemVM.uncheckedItems.isEmpty {
                    if itemVM.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .listRowBackground(AppTheme.surface)
                            .listRowSeparator(.hidden)
                    } else if itemVM.checkedItems.isEmpty {
                        emptyState
                            .listRowBackground(AppTheme.surface)
                            .listRowSeparator(.hidden)
                    }
                }
            } header: {
                if !groupName.isEmpty {
                    HStack(spacing: 6) {
                        Text(groupName)
                            .font(.system(size: 13.5))
                            .foregroundStyle(AppTheme.textSec)
                        Circle()
                            .fill(AppTheme.textTer)
                            .frame(width: 3, height: 3)
                        Text(String(format: loc("%d unpurchased"), itemVM.uncheckedItems.count))
                            .font(.system(size: 13.5))
                            .foregroundStyle(AppTheme.textSec)
                        Spacer()
                    }
                    .textCase(nil)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)
                }
            }

            if !itemVM.checkedItems.isEmpty {
                Section {
                    if checkedExpanded {
                        ForEach(itemVM.checkedItems) { item in
                            ItemRowView(
                                item: item,
                                groupColor: groupColor,
                                onCheck: { Task { await itemVM.toggleCheck(item) } },
                                onTap: { editingItem = item }
                            )
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(AppTheme.surface)
                            .listRowSeparatorTint(AppTheme.hairline)
                            .opacity(0.78)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { await itemVM.deleteItem(item) }
                                } label: {
                                    Label(loc("Delete"), systemImage: "trash")
                                }
                            }
                        }
                    }
                } header: {
                    Button {
                        withAnimation(.spring(duration: 0.3)) { checkedExpanded.toggle() }
                    } label: {
                        HStack {
                            Text(String(format: loc("In Cart (%d)"), itemVM.checkedItems.count))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(AppTheme.textSec)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(AppTheme.textTer)
                                .rotationEffect(.degrees(checkedExpanded ? 0 : -90))
                                .animation(.spring(duration: 0.3), value: checkedExpanded)
                        }
                    }
                    .buttonStyle(.plain)
                    .textCase(nil)
                    .padding(.horizontal, 4)
                    .padding(.bottom, 4)
                }
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(AppTheme.gap)
        .scrollContentBackground(.hidden)
        .background(AppTheme.bg)
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 140) }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Text("🛒").font(.system(size: 48))
            Text(loc("No unpurchased items"))
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.textSec)
            Text(loc("Add items from the input below"))
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.textTer)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var composerBar: some View {
        VStack(spacing: 0) {
            if composerFocused {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(allCategories, id: \.key) { cat in
                            Button {
                                selectedCategory = (selectedCategory == cat.key) ? "" : cat.key
                            } label: {
                                HStack(spacing: 5) {
                                    if selectedCategory != cat.key {
                                        Circle().fill(cat.color).frame(width: 8, height: 8)
                                    }
                                    Text(loc(cat.name)).font(.system(size: 13))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(selectedCategory == cat.key ? cat.color : AppTheme.fieldBg)
                                .foregroundStyle(selectedCategory == cat.key ? .white : AppTheme.text)
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            HStack(spacing: 10) {
                TextField(loc("+ Add item…"), text: $composerText)
                    .focused($composerFocused)
                    .accessibilityIdentifier("itemComposer")
                    .font(.system(size: AppTheme.fs))
                    .padding(.horizontal, 14)
                    .frame(height: 46)
                    .background(AppTheme.fieldBg)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.rField))

                if composerFocused {
                    if !composerText.isEmpty {
                        Button(loc("Add")) { addItem() }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .frame(height: 46)
                            .background(groupColor)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.rField))
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Button(loc("Close")) { composerFocused = false }
                            .font(.system(size: 15))
                            .foregroundStyle(AppTheme.textSec)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .animation(.spring(duration: 0.2), value: composerFocused)
            .animation(.spring(duration: 0.15), value: composerText.isEmpty)
        }
        .background(.regularMaterial)
        .overlay(alignment: .top) { Divider() }
        .animation(.spring(duration: 0.28), value: composerFocused)
    }

    private func addItem() {
        let trimmed = composerText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let cat = selectedCategory
        composerText = ""
        selectedCategory = ""
        Task { await itemVM.addItem(name: trimmed, category: cat) }
    }
}

// MARK: - Item Row

struct ItemRowView: View {
    let item: Item
    let groupColor: Color
    let onCheck: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                checkCircle
                    .onTapGesture { onCheck() }

                if !item.category.isEmpty {
                    Circle()
                        .fill(AppTheme.categoryColor(item.category))
                        .frame(width: 10, height: 10)
                }

                itemContent
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .frame(minHeight: AppTheme.rowH)
            .opacity(item.isChecked ? 0.78 : 1)
        }
        .buttonStyle(.plain)
    }

    private var checkCircle: some View {
        ZStack {
            Circle().fill(item.isChecked ? groupColor : Color.clear)
            Circle().strokeBorder(
                item.isChecked ? groupColor : AppTheme.textTer,
                lineWidth: 1.8
            )
            if item.isChecked {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .frame(width: 26, height: 26)
        .animation(.spring(duration: 0.22), value: item.isChecked)
        .contentShape(Circle())
    }

    private var itemContent: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 8) {
                Text(item.name)
                    .font(.system(size: 16.5, weight: .medium))
                    .strikethrough(item.isChecked)
                    .foregroundStyle(item.isChecked ? AppTheme.textTer : AppTheme.text)

                if !item.quantity.isEmpty {
                    Text(item.quantity)
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textSec)
                }
            }

            if !item.memo.isEmpty {
                HStack(spacing: 4) {
                    Text("📝").font(.system(size: 11))
                    Text(item.memo)
                        .font(.system(size: 12.5))
                        .foregroundStyle(AppTheme.textTer)
                        .lineLimit(1)
                }
            } else if !item.addedByName.isEmpty {
                Text("\(item.addedByName) \(loc("added")) ・ \(relativeTime(from: item.createdAt))")
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppTheme.textTer)
            }
        }
    }
}

private func relativeTime(from iso: String) -> String {
    let fmt = ISO8601DateFormatter()
    fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    guard let date = fmt.date(from: iso) ?? ISO8601DateFormatter().date(from: iso) else { return "" }
    let secs = Int(-date.timeIntervalSinceNow)
    if secs < 60 { return loc("Just now") }
    if secs < 3600 { return String(format: loc("%d min ago"), secs / 60) }
    if secs < 86400 { return String(format: loc("%d hr ago"), secs / 3600) }
    return String(format: loc("%d day ago"), secs / 86400)
}

// MARK: - Item Edit Sheet

struct ItemDetailEditSheet: View {
    let itemVM: ItemViewModel
    let item: Item
    let groupColor: Color
    var customCategories: [GroupCategory] = []

    var allCategories: [(key: String, name: String, color: Color)] {
        AppTheme.categories + customCategories.map { (key: $0.name, name: $0.name, color: Color(hex: $0.color)) }
    }

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var quantity = ""
    @State private var category = ""
    @State private var memo = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    field(label: loc("Item Name")) {
                        TextField(loc("e.g. Milk"), text: $name)
                            .font(.system(size: 16))
                            .padding(.horizontal, 14)
                            .frame(height: 50)
                            .background(AppTheme.fieldBg)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.rField))
                    }

                    field(label: loc("Quantity")) {
                        TextField(loc("e.g. 2 / 300g"), text: $quantity)
                            .font(.system(size: 16))
                            .padding(.horizontal, 14)
                            .frame(height: 50)
                            .background(AppTheme.fieldBg)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.rField))
                    }

                    field(label: loc("Category")) {
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
                            spacing: 8
                        ) {
                            ForEach(allCategories, id: \.key) { cat in
                                Button {
                                    category = (category == cat.key) ? "" : cat.key
                                } label: {
                                    HStack(spacing: 5) {
                                        Circle().fill(cat.color).frame(width: 7, height: 7)
                                        Text(loc(cat.name)).font(.system(size: 13)).lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(category == cat.key ? cat.color.opacity(0.15) : AppTheme.fieldBg)
                                    .foregroundStyle(category == cat.key ? cat.color : AppTheme.textSec)
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.rChip))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.rChip)
                                            .stroke(category == cat.key ? cat.color : Color.clear, lineWidth: 1.5)
                                    )
                                }
                            }
                        }
                    }

                    field(label: loc("Memo")) {
                        TextField(loc("Optional"), text: $memo, axis: .vertical)
                            .font(.system(size: 16))
                            .padding(14)
                            .background(AppTheme.fieldBg)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.rField))
                            .lineLimit(3...5)
                    }

                    Button {
                        Task { await itemVM.deleteItem(item); dismiss() }
                    } label: {
                        Text(loc("Delete This Item"))
                            .font(.system(size: 16, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(AppTheme.deleteBg)
                            .foregroundStyle(AppTheme.deleteText)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.rBtn))
                    }
                }
                .padding(20)
            }
            .background(AppTheme.bg)
            .navigationTitle(loc("Edit Item"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc("Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(loc("Save")) {
                        Task {
                            await itemVM.updateItem(item, name: name, quantity: quantity, category: category, memo: memo)
                            if itemVM.errorMessage == nil { dismiss() }
                        }
                    }
                    .foregroundStyle(groupColor)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.large])
        .onAppear {
            name = item.name
            quantity = item.quantity
            category = item.category
            memo = item.memo
        }
    }

    @ViewBuilder
    private func field<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(AppTheme.textSec)
            content()
        }
    }
}
