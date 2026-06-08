import SwiftUI

struct ListDetailView: View {
    let list: ShoppingListBrief
    let groupId: Int
    let groupColor: Color

    @State private var itemVM: ItemViewModel
    @State private var checkedExpanded = true
    @State private var editingItem: Item?
    @State private var showClearConfirm = false
    @State private var composerText = ""
    @State private var selectedCategory = ""
    @FocusState private var composerFocused: Bool

    init(list: ShoppingListBrief, groupId: Int, groupColor: Color) {
        self.list = list
        self.groupId = groupId
        self.groupColor = groupColor
        _itemVM = State(initialValue: ItemViewModel(groupId: groupId, listId: list.id))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            itemsScrollView
            composerBar
        }
        .background(AppTheme.bg)
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .sheet(item: $editingItem) { item in
            ItemDetailEditSheet(itemVM: itemVM, item: item, groupColor: groupColor)
        }
        .confirmationDialog(
            "チェック済みをすべて削除しますか？",
            isPresented: $showClearConfirm,
            titleVisibility: .visible
        ) {
            Button("削除する", role: .destructive) {
                Task { await itemVM.clearCheckedItems() }
            }
        }
        .alert("エラー", isPresented: Binding(
            get: { itemVM.errorMessage != nil },
            set: { if !$0 { itemVM.errorMessage = nil } }
        )) {
            Button("OK") { itemVM.errorMessage = nil }
        } message: {
            Text(itemVM.errorMessage ?? "")
        }
        .task { itemVM.start() }
        .onDisappear { itemVM.stop() }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                if !itemVM.checkedItems.isEmpty {
                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Label("買い物完了（チェック済みを削除）", systemImage: "checkmark.circle")
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
    }

    private var itemsScrollView: some View {
        ScrollView {
            VStack(spacing: AppTheme.secGap) {
                if !itemVM.uncheckedItems.isEmpty {
                    itemsCard(items: itemVM.uncheckedItems)
                } else if itemVM.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else if itemVM.checkedItems.isEmpty {
                    emptyState
                }

                if !itemVM.checkedItems.isEmpty {
                    checkedSection
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, AppTheme.secGap)
            .padding(.bottom, 140)
        }
    }

    private func itemsCard(items: [Item]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                ItemRowView(
                    item: item,
                    groupColor: groupColor,
                    onCheck: { Task { await itemVM.toggleCheck(item) } },
                    onTap: { editingItem = item }
                )
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        Task { await itemVM.deleteItem(item) }
                    } label: {
                        Label("削除", systemImage: "trash")
                    }
                }
                if i < items.count - 1 {
                    Divider().padding(.leading, 54)
                }
            }
        }
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.rCard))
        .cardShadow()
    }

    private var checkedSection: some View {
        VStack(spacing: AppTheme.gap) {
            Button {
                withAnimation(.spring(duration: 0.3)) {
                    checkedExpanded.toggle()
                }
            } label: {
                HStack {
                    Text("カゴに入れた (\(itemVM.checkedItems.count))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(AppTheme.textSec)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(AppTheme.textTer)
                        .rotationEffect(.degrees(checkedExpanded ? 0 : -90))
                        .animation(.spring(duration: 0.3), value: checkedExpanded)
                }
                .padding(.horizontal, 4)
            }
            .buttonStyle(.plain)

            if checkedExpanded {
                itemsCard(items: itemVM.checkedItems)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .opacity(0.78)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Text("🛒").font(.system(size: 48))
            Text("未購入の商品はありません")
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.textSec)
            Text("下の入力欄から商品を追加してください")
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
                        ForEach(AppTheme.categories, id: \.name) { cat in
                            Button {
                                selectedCategory = (selectedCategory == cat.name) ? "" : cat.name
                            } label: {
                                HStack(spacing: 5) {
                                    if selectedCategory != cat.name {
                                        Circle().fill(cat.color).frame(width: 8, height: 8)
                                    }
                                    Text(cat.name).font(.system(size: 13))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(selectedCategory == cat.name ? cat.color : AppTheme.fieldBg)
                                .foregroundStyle(selectedCategory == cat.name ? .white : AppTheme.text)
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
                TextField("＋ 商品を追加…", text: $composerText)
                    .focused($composerFocused)
                    .font(.system(size: AppTheme.fs))
                    .padding(.horizontal, 14)
                    .frame(height: 46)
                    .background(AppTheme.fieldBg)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.rField))

                if composerFocused {
                    if !composerText.isEmpty {
                        Button("追加") { addItem() }
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .frame(height: 46)
                            .background(groupColor)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.rField))
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        Button("閉じる") { composerFocused = false }
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
                Text("\(item.addedByName)が追加 ・ \(relativeTime(from: item.createdAt))")
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
    if secs < 60 { return "たった今" }
    if secs < 3600 { return "\(secs / 60)分前" }
    if secs < 86400 { return "\(secs / 3600)時間前" }
    return "\(secs / 86400)日前"
}

// MARK: - Item Edit Sheet

struct ItemDetailEditSheet: View {
    let itemVM: ItemViewModel
    let item: Item
    let groupColor: Color

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var quantity = ""
    @State private var category = ""
    @State private var memo = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    field(label: "商品名") {
                        TextField("例: 牛乳", text: $name)
                            .font(.system(size: 16))
                            .padding(.horizontal, 14)
                            .frame(height: 50)
                            .background(AppTheme.fieldBg)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.rField))
                    }

                    field(label: "数量") {
                        TextField("例: 2本 / 300g", text: $quantity)
                            .font(.system(size: 16))
                            .padding(.horizontal, 14)
                            .frame(height: 50)
                            .background(AppTheme.fieldBg)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.rField))
                    }

                    field(label: "カテゴリ") {
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3),
                            spacing: 8
                        ) {
                            ForEach(AppTheme.categories, id: \.name) { cat in
                                Button {
                                    category = (category == cat.name) ? "" : cat.name
                                } label: {
                                    HStack(spacing: 5) {
                                        Circle().fill(cat.color).frame(width: 7, height: 7)
                                        Text(cat.name).font(.system(size: 13)).lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(category == cat.name ? cat.color.opacity(0.15) : AppTheme.fieldBg)
                                    .foregroundStyle(category == cat.name ? cat.color : AppTheme.textSec)
                                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.rChip))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.rChip)
                                            .stroke(category == cat.name ? cat.color : Color.clear, lineWidth: 1.5)
                                    )
                                }
                            }
                        }
                    }

                    field(label: "メモ") {
                        TextField("任意", text: $memo, axis: .vertical)
                            .font(.system(size: 16))
                            .padding(14)
                            .background(AppTheme.fieldBg)
                            .clipShape(RoundedRectangle(cornerRadius: AppTheme.rField))
                            .lineLimit(3...5)
                    }

                    Button {
                        Task { await itemVM.deleteItem(item); dismiss() }
                    } label: {
                        Text("このアイテムを削除")
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
            .navigationTitle("商品を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
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
