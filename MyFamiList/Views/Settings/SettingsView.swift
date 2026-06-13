import SwiftUI

struct SettingsView: View {
    let user: AppUser
    let groupVM: GroupViewModel
    let onSignOut: () -> Void

    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.openURL) private var openURL
    @State private var showSignOutConfirm = false
    @State private var showDeleteAccountConfirm = false
    @State private var showEditProfile = false
    @State private var showCategoryManager = false
    @State private var showPasswordChange = false
    @State private var notificationInterval: Int = 15
    @State private var showIntervalPicker = false

    private var currentUser: AppUser { authVM.currentUser ?? user }

    private var deleteAccountWarning: String {
        let ownedCount = groupVM.groups.filter { $0.isOwner }.count
        if ownedCount > 0 {
            return "アカウントを削除すると、あなたがオーナーの\(ownedCount)個のグループとすべてのリストも削除されます。この操作は取り消せません。"
        }
        return "アカウントとすべてのデータが削除されます。この操作は取り消せません。"
    }

    var body: some View {
        VStack(spacing: 0) {
            AppHeader("設定", sub: "無料プラン")

            ScrollView {
                VStack(spacing: AppTheme.secGap) {
                    profileCard
                    settingsGroups
                    versionText
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 40)
            }
            .background(AppTheme.bg)
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            if let interval = try? await APIClient.shared.getNotificationInterval() {
                notificationInterval = interval
            }
        }
        .confirmationDialog(
            "サインアウトしますか？",
            isPresented: $showSignOutConfirm,
            titleVisibility: .visible
        ) {
            Button("サインアウト", role: .destructive) { onSignOut() }
        }
        .confirmationDialog(
            deleteAccountWarning,
            isPresented: $showDeleteAccountConfirm,
            titleVisibility: .visible
        ) {
            Button("アカウントを削除", role: .destructive) {
                Task { await authVM.deleteAccount() }
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileSheet(user: currentUser) { updatedUser in
                authVM.currentUser = updatedUser
                Task { await groupVM.refreshAll() }
            }
        }
        .sheet(isPresented: $showCategoryManager) {
            CategoryManagerSheet(groupVM: groupVM)
        }
        .sheet(isPresented: $showPasswordChange) {
            PasswordChangeSheet()
        }
    }

    private var profileCard: some View {
        Button { showEditProfile = true } label: {
            HStack(spacing: 14) {
                AvatarView(
                    name: currentUser.displayName.isEmpty ? "U" : currentUser.displayName,
                    size: 50,
                    colorHex: currentUser.avatarColor.isEmpty ? nil : currentUser.avatarColor,
                    emoji: currentUser.avatarEmoji.isEmpty ? nil : currentUser.avatarEmoji,
                    photo: currentUser.avatarPhoto.isEmpty ? nil : currentUser.avatarPhoto
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(currentUser.displayName.isEmpty ? "ユーザー" : currentUser.displayName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppTheme.text)
                    Text(signInMethod)
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textSec)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textTer)
            }
            .padding(16)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.rCard))
            .cardShadow()
        }
        .buttonStyle(.plain)
    }

    private func intervalLabel(_ minutes: Int) -> String {
        switch minutes {
        case 0:  return "なし"
        case 5:  return "5分"
        case 15: return "15分"
        case 30: return "30分"
        case 60: return "1時間"
        default: return "\(minutes)分"
        }
    }

    private var signInMethod: String {
        switch currentUser.provider {
        case "apple":  return "Apple ID でサインイン中"
        case "google": return "Google でサインイン中"
        case "email":  return currentUser.email.isEmpty ? "メールでサインイン中" : currentUser.email
        default:       return currentUser.provider
        }
    }

    private var isEmailUser: Bool { currentUser.provider == "email" }

    private var settingsGroups: some View {
        VStack(spacing: AppTheme.secGap) {
            settingsCard {
                settingsRow(icon: "clock.arrow.circlepath", iconColor: Color(hex: "#E0A03A"), label: "通知間隔") {
                    Text(intervalLabel(notificationInterval))
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textSec)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textTer)
                }
                .onTapGesture { showIntervalPicker = true }
            }
            .confirmationDialog("通知間隔", isPresented: $showIntervalPicker, titleVisibility: .visible) {
                ForEach([0, 5, 15, 30, 60], id: \.self) { minutes in
                    Button(intervalLabel(minutes)) {
                        notificationInterval = minutes
                        Task { try? await APIClient.shared.updateNotificationInterval(minutes) }
                    }
                }
                Button("キャンセル", role: .cancel) {}
            }

            settingsCard {
                if isEmailUser {
                    settingsRow(icon: "key.fill", iconColor: Color(hex: "#5690C9"), label: "パスワードを変更") {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.textTer)
                    }
                    .onTapGesture { showPasswordChange = true }
                    Divider().padding(.leading, 58)
                }
                settingsRow(icon: "tag.fill", iconColor: Color(hex: "#54A862"), label: "カテゴリの管理") {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textTer)
                }
                .onTapGesture { showCategoryManager = true }
                Divider().padding(.leading, 58)
                settingsRow(icon: "questionmark.circle.fill", iconColor: Color(hex: "#7C8AA1"), label: "プライバシーポリシー") {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textTer)
                }
                .onTapGesture {
                    openURL(URL(string: "https://kotoragk.com/familist/privacy")!)
                }
                Divider().padding(.leading, 58)
                settingsRow(icon: "rectangle.portrait.and.arrow.right", iconColor: Color(hex: "#D9695F"), label: "サインアウト") {
                    EmptyView()
                }
                .onTapGesture { showSignOutConfirm = true }
                Divider().padding(.leading, 58)
                settingsRow(icon: "trash.fill", iconColor: Color(hex: "#C0392B"), label: "アカウントを削除") {
                    EmptyView()
                }
                .onTapGesture { showDeleteAccountConfirm = true }
            }
        }
    }

    @ViewBuilder
    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.rCard))
        .cardShadow()
    }

    @ViewBuilder
    private func settingsRow<Trailing: View>(
        icon: String,
        iconColor: Color,
        label: String,
        @ViewBuilder trailing: () -> Trailing
    ) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor)
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
            }
            Text(label)
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.text)
            Spacer()
            trailing()
        }
        .padding(.horizontal, 16)
        .frame(height: AppTheme.rowH)
    }

    private var versionText: some View {
        Text("MyFamiList v1.0.0")
            .font(.system(size: 13))
            .foregroundStyle(AppTheme.textTer)
    }
}
