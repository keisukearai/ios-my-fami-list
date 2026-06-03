import SwiftUI

struct MainTabView: View {
    let user: AppUser
    let onSignOut: () -> Void

    @State private var groupVM = GroupViewModel()
    @State private var selectedTab = 0
    @State private var showGroupPicker = false

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ListsScreenView(
                    groupVM: groupVM,
                    onGroupPickerTap: { showGroupPicker = true }
                )
            }
            .tabItem { Label("リスト", systemImage: "cart") }
            .tag(0)

            NavigationStack {
                MembersView(group: groupVM.currentGroup)
            }
            .tabItem { Label("メンバー", systemImage: "person.2") }
            .tag(1)

            NavigationStack {
                SettingsView(user: user, onSignOut: onSignOut)
            }
            .tabItem { Label("設定", systemImage: "gearshape") }
            .tag(2)
        }
        .tint(AppTheme.primary)
        .sheet(isPresented: $showGroupPicker) {
            GroupPickerSheet(groupVM: groupVM)
        }
        .task {
            groupVM.start()
        }
        .onDisappear {
            groupVM.stop()
        }
    }
}
