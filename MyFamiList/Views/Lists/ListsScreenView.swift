import SwiftUI

struct ListsScreenView: View {
    let groupVM: GroupViewModel
    let onGroupPickerTap: () -> Void

    @Environment(PurchaseService.self) private var purchaseService
    @Environment(NetworkMonitor.self) private var networkMonitor
    @State private var showAddSheet = false
    @State private var showPaywall = false
    @State private var newListName = ""

    var body: some View {
        VStack(spacing: 0) {
            AppHeader(String(localized: "Lists")) {
                groupPickerPill
            } right: {
                HStack(spacing: 8) {
                    if !networkMonitor.isConnected {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 14))
                            .foregroundStyle(AppTheme.textTer)
                    }
                    memberAvatarStack
                        .onTapGesture { onGroupPickerTap() }
                }
            }

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
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showAddSheet) { addListSheet }
        .sheet(isPresented: $showPaywall) { PaywallSheet() }
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
        List {
            if group.lists.isEmpty {
                emptyListsView
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            } else {
                ForEach(group.lists) { list in
                    ZStack {
                        NavigationLink(value: list) { EmptyView() }.opacity(0)
                        ListCard(list: list, groupColor: AppTheme.primary)
                    }
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: AppTheme.gap, trailing: 16))
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if group.isOwner {
                            Button(role: .destructive) {
                                Task { await groupVM.deleteList(list) }
                            } label: {
                                Label(String(localized: "Delete"), systemImage: "trash")
                            }
                        }
                    }
                }
            }
            addListButton
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            if !purchaseService.isPro {
                Text("Free plan: up to 2 lists")
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppTheme.textTer)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 0, trailing: 16))
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(AppTheme.bg)
        .contentMargins(.top, 12, for: .scrollContent)
    }

    private var groupPickerPill: some View {
        Button(action: onGroupPickerTap) {
            HStack(spacing: 6) {
                if let group = groupVM.currentGroup {
                    Text(group.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(AppTheme.text)
                } else {
                    Text("Select Group")
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
        let overflow = members.count - 4
        return HStack(spacing: -8) {
            ForEach(Array(members.prefix(4).enumerated()), id: \.offset) { i, member in
                AvatarView(
                    name: member.displayName,
                    size: 28,
                    colorHex: member.avatarColor.isEmpty ? nil : member.avatarColor,
                    emoji: member.avatarEmoji.isEmpty ? nil : member.avatarEmoji,
                    photo: member.avatarPhoto.isEmpty ? nil : member.avatarPhoto
                )
                .overlay(Circle().stroke(AppTheme.bg, lineWidth: 2))
                .zIndex(Double(4 - i))
            }
            if overflow > 0 {
                ZStack {
                    Circle().fill(AppTheme.surface2)
                    Text("+\(overflow)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppTheme.textSec)
                }
                .frame(width: 28, height: 28)
                .overlay(Circle().stroke(AppTheme.bg, lineWidth: 2))
                .zIndex(0)
            }
        }
    }

    private var addListButton: some View {
        Button {
            let listCount = groupVM.currentGroup?.lists.count ?? 0
            if purchaseService.isPro || listCount < 2 {
                showAddSheet = true
            } else {
                showPaywall = true
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .medium))
                Text("Add List")
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
            Text("No lists")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(AppTheme.textSec)
            Text("You can create a list from \"Add List\"")
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
            Text("No groups")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppTheme.text)
            Text("Create a group or join with an invite code.")
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.textSec)
                .multilineTextAlignment(.center)
            Button { onGroupPickerTap() } label: {
                Text("Create Group")
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
                Section(String(localized: "List name")) {
                    TextField(String(localized: "e.g. This week's supermarket"), text: $newListName)
                        .accessibilityIdentifier("addListTextField")
                }
            }
            .navigationTitle(String(localized: "Add List"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { showAddSheet = false; newListName = "" }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Add")) {
                        Task {
                            await groupVM.createList(name: newListName)
                            showAddSheet = false
                            newListName = ""
                        }
                    }
                    .disabled(newListName.trimmingCharacters(in: .whitespaces).isEmpty)
                    .accessibilityIdentifier("addListConfirmButton")
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
        if list.itemCount == 0 { return String(localized: "No items") }
        if isDone { return String(localized: "Done 🎉") }
        return String(format: String(localized: "%d remaining · %d total"), list.uncheckedCount, list.itemCount)
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
