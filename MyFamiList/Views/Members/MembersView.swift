import SwiftUI

struct MembersView: View {
    let group: FamilyGroup?

    @Environment(GroupViewModel.self) private var groupVM
    @State private var showInvite = false
    @State private var kickTargetMember: Member?

    private var headerSub: String? {
        guard let group else { return nil }
        return "\(group.members.count)人が参加中"
    }

    var body: some View {
        VStack(spacing: 0) {
            AppHeader("メンバー", sub: headerSub)

            Group {
                if let group {
                    mainContent(group: group)
                } else {
                    noGroupView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .toolbar(.hidden, for: .navigationBar)
        .alert("エラー", isPresented: Binding(
            get: { groupVM.errorMessage != nil },
            set: { if !$0 { groupVM.errorMessage = nil } }
        )) {
            Button("OK") {}
        } message: {
            Text(groupVM.errorMessage ?? "")
        }
        .sheet(isPresented: $showInvite) {
            if let group {
                InviteCodeSheet(group: group)
            }
        }
        .confirmationDialog(
            "「\(kickTargetMember?.displayName ?? "")」をグループから削除しますか？",
            isPresented: Binding(get: { kickTargetMember != nil }, set: { if !$0 { kickTargetMember = nil } }),
            titleVisibility: .visible
        ) {
            Button("削除する", role: .destructive) {
                if let member = kickTargetMember, let groupId = group?.id {
                    Task { await groupVM.kickMember(groupId: groupId, userId: member.id) }
                }
                kickTargetMember = nil
            }
        }
    }

    private func mainContent(group: FamilyGroup) -> some View {
        ScrollView {
            VStack(spacing: AppTheme.secGap) {
                memberListCard(group: group)
                inviteButton
                Text("無料プランは3人まで")
                    .font(.system(size: 12.5))
                    .foregroundStyle(AppTheme.textTer)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 28)
        }
        .background(AppTheme.bg)
    }

    private func memberListCard(group: FamilyGroup) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(group.members.enumerated()), id: \.element.id) { i, member in
                memberRow(member: member, group: group)
                    .contextMenu {
                        if group.isOwner && member.id != group.ownerId {
                            Button(role: .destructive) {
                                kickTargetMember = member
                            } label: {
                                Label("グループから削除", systemImage: "person.fill.xmark")
                            }
                        }
                    }
                if i < group.members.count - 1 {
                    Divider().padding(.leading, 70)
                }
            }
        }
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.rCard))
        .cardShadow()
    }

    private func memberRow(member: Member, group: FamilyGroup) -> some View {
        HStack(spacing: 14) {
            AvatarView(
                name: member.displayName,
                size: 42,
                colorHex: member.avatarColor.isEmpty ? nil : member.avatarColor,
                emoji: member.avatarEmoji.isEmpty ? nil : member.avatarEmoji,
                photo: member.avatarPhoto.isEmpty ? nil : member.avatarPhoto
            )

            VStack(alignment: .leading, spacing: 4) {
                Text(member.displayName)
                    .font(.system(size: 16.5, weight: .semibold))
                    .foregroundStyle(AppTheme.text)
                Text(member.id == group.ownerId ? "オーナー" : "メンバー")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textSec)
            }

            Spacer()

            if member.id == group.ownerId {
                Image(systemName: "crown.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.softText)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }

    private var inviteButton: some View {
        Button { showInvite = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 17))
                Text("メンバーを招待")
                    .font(.system(size: 17, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(AppTheme.primary)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.rBtn))
        }
    }

    private var noGroupView: some View {
        VStack(spacing: 14) {
            Image(systemName: "person.3")
                .font(.system(size: 52))
                .foregroundStyle(AppTheme.textTer)
            Text("グループを選択してください")
                .font(.system(size: 17))
                .foregroundStyle(AppTheme.textSec)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.bg)
    }
}

// MARK: - Invite Code Sheet

struct InviteCodeSheet: View {
    let group: FamilyGroup
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("このコードを相手に共有してください")
                    .font(.system(size: 14))
                    .foregroundStyle(AppTheme.textSec)
                    .multilineTextAlignment(.center)

                Text(group.inviteCode)
                    .font(.system(size: 34, weight: .bold, design: .monospaced))
                    .foregroundStyle(AppTheme.primary)
                    .padding(.vertical, 24)
                    .padding(.horizontal, 32)
                    .background(AppTheme.soft)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.rCard))
                    .onTapGesture { copyCode() }

                Button { copyCode() } label: {
                    Label(copied ? "コピーしました" : "コードをコピー",
                          systemImage: copied ? "checkmark" : "doc.on.doc")
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(AppTheme.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.rBtn))
                }

                Text("アプリをインストールした相手にこのコードを入力してもらうとグループに参加できます。")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textSec)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding(24)
            .background(AppTheme.bg)
            .navigationTitle("「\(group.name)」に招待")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func copyCode() {
        UIPasteboard.general.string = group.inviteCode
        copied = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            copied = false
        }
    }
}
