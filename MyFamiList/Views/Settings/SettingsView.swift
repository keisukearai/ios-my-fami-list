import SwiftUI

struct SettingsView: View {
    let user: AppUser
    let onSignOut: () -> Void

    @State private var showSignOutConfirm = false
    @State private var notificationInterval: Int = 15
    @State private var showIntervalPicker = false

    var body: some View {
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
        .navigationTitle("設定")
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
    }

    private var profileCard: some View {
        HStack(spacing: 14) {
            AvatarView(
                name: user.displayName.isEmpty ? "U" : user.displayName,
                size: 50,
                emoji: user.avatarEmoji.isEmpty ? nil : user.avatarEmoji
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(user.displayName.isEmpty ? "ユーザー" : user.displayName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AppTheme.text)
                Text(signInMethod)
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textSec)
            }

            Spacer()
        }
        .padding(16)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.rCard))
        .cardShadow()
    }

    private func intervalLabel(_ minutes: Int) -> String {
        switch minutes {
        case 5:  return "5分"
        case 15: return "15分"
        case 30: return "30分"
        case 60: return "1時間"
        default: return "\(minutes)分"
        }
    }

    private var signInMethod: String {
        switch user.provider {
        case "apple": return "Apple ID でサインイン中"
        case "google": return "Google でサインイン中"
        default: return user.provider
        }
    }

    private var settingsGroups: some View {
        VStack(spacing: AppTheme.secGap) {
            settingsCard {
                settingsRow(icon: "bell.fill", iconColor: Color(hex: "#5690C9"), label: "プッシュ通知") {
                    Toggle("", isOn: .constant(true))
                        .tint(AppTheme.primary)
                        .labelsHidden()
                }
                Divider().padding(.leading, 58)
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
                ForEach([5, 15, 30, 60], id: \.self) { minutes in
                    Button(intervalLabel(minutes)) {
                        notificationInterval = minutes
                        Task { try? await APIClient.shared.updateNotificationInterval(minutes) }
                    }
                }
                Button("キャンセル", role: .cancel) {}
            }

            settingsCard {
                settingsRow(icon: "tag.fill", iconColor: Color(hex: "#54A862"), label: "カテゴリの管理") {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textTer)
                }
                Divider().padding(.leading, 58)
                settingsRow(icon: "questionmark.circle.fill", iconColor: Color(hex: "#7C8AA1"), label: "ヘルプ") {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textTer)
                }
                Divider().padding(.leading, 58)
                settingsRow(icon: "rectangle.portrait.and.arrow.right", iconColor: Color(hex: "#D9695F"), label: "サインアウト") {
                    EmptyView()
                }
                .onTapGesture { showSignOutConfirm = true }
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
