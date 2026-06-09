import SwiftUI

struct ListsScreenView: View {
    let groupVM: GroupViewModel
    let onGroupPickerTap: () -> Void

    @State private var showAddSheet = false
    @State private var newListName = ""

    var body: some View {
        Group {
            if groupVM.isLoading && groupVM.groups.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.bg)
            } else if groupVM.groups.isEmpty {
                noGroupsView
            } else if let group = groupVM.currentGroup {
                mainContent(group: group)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.bg)
            }
        }
        .navigationTitle("リスト")
        .toolbar { toolbarContent }
        .sheet(isPresented: $showAddSheet) { addListSheet }
        .navigationDestination(for: ShoppingListBrief.self) { list in
            let group = groupVM.currentGroup
            ListDetailView(
                list: list,
                groupId: group?.id ?? 0,
                groupColor: AppTheme.primary,
                groupName: group?.name ?? ""
            )
        }
    }

    private func mainContent(group: FamilyGroup) -> some View {
        ScrollView {
            VStack(spacing: AppTheme.gap) {
                if group.lists.isEmpty {
                    emptyListsView
                } else {
                    ForEach(group.lists) { list in
                        NavigationLink(value: list) {
                            ListCard(list: list, groupColor: AppTheme.primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                addListButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(AppTheme.bg)
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            groupPickerPill
        }
        ToolbarItem(placement: .topBarTrailing) {
            memberAvatarStack
                .onTapGesture { onGroupPickerTap() }
        }
    }

    private var groupPickerPill: some View {
        Button(action: onGroupPickerTap) {
            HStack(spacing: 6) {
                if let group = groupVM.currentGroup {
                    Text(group.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.text)
                } else {
                    Text("グループを選択")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.textSec)
                }
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(AppTheme.textTer)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(AppTheme.surface)
            .clipShape(Capsule())
            .shadow(color: AppTheme.sep, radius: 3, x: 0, y: 1)
        }
    }

    private var memberAvatarStack: some View {
        let members = groupVM.currentGroup?.members ?? []
        return HStack(spacing: -8) {
            ForEach(Array(members.prefix(4).enumerated()), id: \.offset) { i, member in
                AvatarView(name: member.displayName, size: 28, emoji: member.avatarEmoji)
                    .overlay(Circle().stroke(AppTheme.bg, lineWidth: 2))
                    .zIndex(Double(4 - i))
            }
        }
    }

    private var addListButton: some View {
        Button { showAddSheet = true } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .medium))
                Text("リストを追加")
                    .font(.system(size: 16, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .foregroundStyle(AppTheme.textTer)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.rCard)
                    .stroke(AppTheme.textTer, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            )
        }
    }

    private var emptyListsView: some View {
        VStack(spacing: 14) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.textTer)
            Text("リストがありません")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(AppTheme.textSec)
            Text("「リストを追加」からリストを作成できます")
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textTer)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private var noGroupsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 52))
                .foregroundStyle(AppTheme.textTer)
            Text("グループがありません")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppTheme.text)
            Text("グループを作成するか\n招待コードで参加してください")
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.textSec)
                .multilineTextAlignment(.center)
            Button { onGroupPickerTap() } label: {
                Text("グループを作成")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(height: 50)
                    .padding(.horizontal, 28)
                    .background(AppTheme.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.rBtn))
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.bg)
    }

    private var addListSheet: some View {
        NavigationStack {
            Form {
                Section("リスト名") {
                    TextField("例: 今週のスーパー", text: $newListName)
                }
            }
            .navigationTitle("リストを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { showAddSheet = false; newListName = "" }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        Task {
                            await groupVM.createList(name: newListName)
                            showAddSheet = false
                            newListName = ""
                        }
                    }
                    .disabled(newListName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct ListCard: View {
    let list: ShoppingListBrief
    let groupColor: Color

    private var progress: Double {
        guard list.itemCount > 0 else { return 0 }
        let checked = list.itemCount - list.uncheckedCount
        return Double(checked) / Double(list.itemCount)
    }

    private var isDone: Bool { list.itemCount > 0 && list.uncheckedCount == 0 }

    private var subtitle: String {
        if list.itemCount == 0 { return "商品なし" }
        if isDone { return "完了 🎉" }
        return "残り \(list.uncheckedCount)品 ・ 全\(list.itemCount)品"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                progressRing
                VStack(alignment: .leading, spacing: 3) {
                    Text(list.name)
                        .font(.system(size: 17.5, weight: .semibold))
                        .foregroundStyle(AppTheme.text)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.system(size: 13.5))
                        .foregroundStyle(AppTheme.textSec)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppTheme.textTer)
            }
            .padding(.horizontal, 15)
            .padding(.vertical, 15)

            if !list.categories.isEmpty {
                Divider()
                    .background(AppTheme.hairline)
                    .padding(.leading, 15)
                categoryDots
                    .padding(.horizontal, 15)
                    .padding(.vertical, 10)
            }
        }
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.rCard))
        .cardShadow()
    }

    private var progressRing: some View {
        ZStack {
            Circle()
                .stroke(groupColor.opacity(0.15), lineWidth: 3.5)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(groupColor, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
            if isDone {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(groupColor)
            } else {
                Text("\(list.uncheckedCount)")
                    .font(.system(size: list.uncheckedCount >= 10 ? 10 : 12, weight: .semibold))
                    .foregroundStyle(groupColor)
            }
        }
        .frame(width: 38, height: 38)
    }

    private var categoryDots: some View {
        HStack(spacing: 5) {
            ForEach(list.categories, id: \.self) { cat in
                HStack(spacing: 4) {
                    Circle()
                        .fill(AppTheme.categoryColor(cat))
                        .frame(width: 8, height: 8)
                    Text(cat)
                        .font(.system(size: 12.5))
                        .foregroundStyle(AppTheme.textTer)
                        .lineLimit(1)
                }
            }
            Spacer()
        }
    }
}
