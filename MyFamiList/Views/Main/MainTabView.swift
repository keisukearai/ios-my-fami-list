import SwiftUI

struct MainTabView: View {
    let user: AppUser
    let onSignOut: () -> Void

    @State private var groupVM = GroupViewModel()
    @State private var selectedTab = 0
    @State private var showGroupPicker = false
    @State private var listsPath = NavigationPath()
    @Environment(InviteHandler.self) private var inviteHandler

    init(user: AppUser, onSignOut: @escaping () -> Void) {
        self.user = user
        self.onSignOut = onSignOut
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                NavigationStack(path: $listsPath) {
                    ListsScreenView(
                        groupVM: groupVM,
                        onGroupPickerTap: { showGroupPicker = true }
                    )
                }
                .tag(0)

                NavigationStack {
                    MembersView(group: groupVM.currentGroup)
                }
                .tag(1)

                NavigationStack {
                    SettingsView(user: user, groupVM: groupVM, onSignOut: onSignOut)
                }
                .tag(2)
            }

            if listsPath.isEmpty {
                CustomTabBar(selectedTab: $selectedTab)
            }
        }
        .environment(groupVM)
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showGroupPicker) {
            GroupPickerSheet(groupVM: groupVM)
        }
        .alert(loc("Join Group"), isPresented: Binding(
            get: { inviteHandler.pendingCode != nil },
            set: { if !$0 { inviteHandler.pendingCode = nil } }
        )) {
            Button(loc("Join")) {
                let code = inviteHandler.pendingCode ?? ""
                inviteHandler.pendingCode = nil
                Task { try? await groupVM.joinGroup(inviteCode: code) }
            }
            Button(loc("Cancel"), role: .cancel) {
                inviteHandler.pendingCode = nil
            }
        } message: {
            if let code = inviteHandler.pendingCode {
                Text("Join group with invite code \"\(code)\"?")
            }
        }
        .task { groupVM.start() }
        .onDisappear { groupVM.stop() }
    }
}

// MARK: - Custom Tab Bar

private struct CustomTabBar: View {
    @Binding var selectedTab: Int

    private var items: [(icon: String, label: String)] {
        [
            ("cart",      loc("Lists")),
            ("person.2",  loc("Members")),
            ("gearshape", loc("Settings")),
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(AppTheme.hairline)
                .frame(height: 0.5)

            HStack(spacing: 0) {
                ForEach(items.indices, id: \.self) { i in
                    Button {
                        selectedTab = i
                    } label: {
                        tabItem(index: i)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("tab_\(items[i].label)")
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 26)
        }
        .background(.regularMaterial)
    }

    private func tabItem(index: Int) -> some View {
        let active = selectedTab == index
        let item = items[index]
        return VStack(spacing: 3) {
            Image(systemName: active ? "\(item.icon).fill" : item.icon)
                .font(.system(size: 24, weight: active ? .semibold : .regular))
                .foregroundStyle(active ? AppTheme.primary : AppTheme.textTer)
            Text(item.label)
                .font(.system(size: 10.5, weight: active ? .semibold : .medium))
                .foregroundStyle(active ? AppTheme.primary : AppTheme.textTer)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 18)
        .contentShape(Rectangle())
    }
}
