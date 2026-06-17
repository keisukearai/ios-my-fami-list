import SwiftUI

struct SettingsView: View {
    let user: AppUser
    let groupVM: GroupViewModel
    let onSignOut: () -> Void

    @Environment(AuthViewModel.self) private var authVM
    @Environment(PurchaseService.self) private var purchaseService
    @Environment(NetworkMonitor.self) private var networkMonitor
    @Environment(\.openURL) private var openURL
    @State private var showSignOutConfirm = false
    @State private var showDeleteAccountConfirm = false
    @State private var showEditProfile = false
    @State private var showCategoryManager = false
    @State private var showPasswordChange = false
    @State private var showPaywall = false
    @State private var notificationInterval: Int = 15
    @State private var showIntervalPicker = false
    @AppStorage(LanguageManager.userDefaultsKey) private var appLanguageRaw: String = "system"
    @State private var showRestartAlert = false
    @State private var showLanguagePicker = false

    private var appLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguageRaw) ?? .system
    }

    private var currentUser: AppUser { authVM.currentUser ?? user }

    private var deleteAccountWarning: String {
        let ownedCount = groupVM.groups.filter { $0.isOwner }.count
        if ownedCount > 0 {
            return String(format: String(localized: "Deleting your account will also delete %d group(s) you own and all lists. This cannot be undone."), ownedCount)
        }
        return String(localized: "Your account and all data will be deleted. This cannot be undone.")
    }

    var body: some View {
        VStack(spacing: 0) {
            AppHeader(String(localized: "Settings"), sub: purchaseService.isPro ? String(localized: "Pro Plan") : String(localized: "Free Plan"))

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
            String(localized: "Sign out?"),
            isPresented: $showSignOutConfirm,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Sign Out"), role: .destructive) { onSignOut() }
        }
        .confirmationDialog(
            deleteAccountWarning,
            isPresented: $showDeleteAccountConfirm,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Delete Account"), role: .destructive) {
                Task { await authVM.deleteAccount() }
            }
        }
        .alert(String(localized: "Language changed. Please restart the app to apply."), isPresented: $showRestartAlert) {
            Button(String(localized: "OK")) {}
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
        .sheet(isPresented: $showPaywall) {
            PaywallSheet()
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
                    Text(currentUser.displayName.isEmpty ? String(localized: "User") : currentUser.displayName)
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
        case 0:  return String(localized: "None")
        case 5:  return String(localized: "5 min")
        case 15: return String(localized: "15 min")
        case 30: return String(localized: "30 min")
        case 60: return String(localized: "1 hour")
        default: return "\(minutes) min"
        }
    }

    private var signInMethod: String {
        switch currentUser.provider {
        case "apple":  return String(localized: "Signed in with Apple ID")
        case "google": return String(localized: "Signed in with Google")
        case "email":  return currentUser.email.isEmpty ? String(localized: "Signed in with Email") : currentUser.email
        default:       return currentUser.provider
        }
    }

    private var isEmailUser: Bool { currentUser.provider == "email" }

    private var settingsGroups: some View {
        VStack(spacing: AppTheme.secGap) {
            if !purchaseService.isPro {
                settingsCard {
                    settingsRow(icon: "crown.fill", iconColor: Color(hex: "#E0A03A"), label: String(localized: "Upgrade to Pro")) {
                        Text("¥300")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AppTheme.textSec)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.textTer)
                    }
                    .onTapGesture { showPaywall = true }
                }
            }

            settingsCard {
                settingsRow(icon: "clock.arrow.circlepath", iconColor: Color(hex: "#E0A03A"), label: String(localized: "Notification Interval")) {
                    Text(intervalLabel(notificationInterval))
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textSec)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textTer)
                }
                .onTapGesture { showIntervalPicker = true }
            }
            .confirmationDialog(String(localized: "Notification Interval"), isPresented: $showIntervalPicker, titleVisibility: .visible) {
                ForEach([0, 5, 15, 30, 60], id: \.self) { minutes in
                    Button(intervalLabel(minutes)) {
                        notificationInterval = minutes
                        Task { try? await APIClient.shared.updateNotificationInterval(minutes) }
                    }
                }
                Button(String(localized: "Cancel"), role: .cancel) {}
            }

            settingsCard {
                settingsRow(icon: "globe", iconColor: Color(hex: "#5690C9"), label: String(localized: "Language")) {
                    Text(appLanguage.displayName)
                        .font(.system(size: 14))
                        .foregroundStyle(AppTheme.textSec)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textTer)
                }
                .onTapGesture { showLanguagePicker = true }
                Divider().padding(.leading, 58)
            }
            .confirmationDialog(String(localized: "Language"), isPresented: $showLanguagePicker, titleVisibility: .visible) {
                ForEach(AppLanguage.allCases, id: \.self) { lang in
                    Button(lang.displayName) {
                        let prev = LanguageManager.shared.currentLanguage
                        LanguageManager.shared.setLanguage(lang)
                        appLanguageRaw = lang.rawValue
                        if lang != prev { showRestartAlert = true }
                    }
                }
                Button(String(localized: "Cancel"), role: .cancel) {}
            }

            settingsCard {
                if isEmailUser {
                    settingsRow(icon: "key.fill", iconColor: Color(hex: "#5690C9"), label: String(localized: "Change Password")) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13))
                            .foregroundStyle(AppTheme.textTer)
                    }
                    .onTapGesture { showPasswordChange = true }
                    Divider().padding(.leading, 58)
                }
                settingsRow(icon: "tag.fill", iconColor: Color(hex: "#54A862"), label: String(localized: "Manage Categories")) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textTer)
                }
                .onTapGesture { showCategoryManager = true }
                Divider().padding(.leading, 58)
                settingsRow(icon: "questionmark.circle.fill", iconColor: Color(hex: "#7C8AA1"), label: String(localized: "Privacy Policy")) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textTer)
                }
                .onTapGesture {
                    openURL(URL(string: "https://kotoragk.com/familist/privacy")!)
                }
                Divider().padding(.leading, 58)
                settingsRow(icon: "rectangle.portrait.and.arrow.right", iconColor: Color(hex: "#D9695F"), label: String(localized: "Sign Out")) {
                    EmptyView()
                }
                .onTapGesture { showSignOutConfirm = true }
                .accessibilityIdentifier("signOutRow")
                Divider().padding(.leading, 58)
                settingsRow(icon: "trash.fill", iconColor: Color(hex: "#C0392B"), label: String(localized: "Delete Account")) {
                    EmptyView()
                }
                .onTapGesture { showDeleteAccountConfirm = true }
                .accessibilityIdentifier("deleteAccountRow")
            }

            settingsCard {
                settingsRow(
                    icon: networkMonitor.isConnected ? "wifi" : "wifi.slash",
                    iconColor: networkMonitor.isConnected ? Color(hex: "#16A368") : Color(hex: "#7C8AA1"),
                    label: String(localized: "Network")
                ) {
                    Text(networkMonitor.isConnected ? String(localized: "Online") : String(localized: "Offline"))
                        .font(.system(size: 14))
                        .foregroundStyle(networkMonitor.isConnected ? Color(hex: "#16A368") : AppTheme.textSec)
                }
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
