import SwiftUI

struct GroupPickerSheet: View {
    let groupVM: GroupViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showCreateGroup = false
    @State private var showJoinGroup = false
    @State private var newGroupName = ""
    @State private var inviteCode = ""
    @State private var isProcessing = false
    @State private var sheetError: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.gap) {
                    if groupVM.groups.isEmpty {
                        noGroupsPlaceholder
                    } else {
                        groupListCard
                    }

                    if let err = sheetError {
                        Text(err)
                            .font(.system(size: 13))
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    joinGroupButton
                    createGroupButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
            .background(AppTheme.bg)
            .navigationTitle("グループ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .sheet(isPresented: $showCreateGroup) { createGroupSheet }
            .sheet(isPresented: $showJoinGroup) { joinGroupSheet }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var groupListCard: some View {
        VStack(spacing: 0) {
            ForEach(groupVM.groups) { group in
                Button {
                    Task {
                        await groupVM.selectGroup(group.id)
                        dismiss()
                    }
                } label: {
                    groupRow(group)
                }
                .buttonStyle(.plain)

                if group.id != groupVM.groups.last?.id {
                    Divider().padding(.leading, 60)
                }
            }
        }
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.rCard))
        .cardShadow()
    }

    private func groupRow(_ group: FamilyGroupBrief) -> some View {
        let isSelected = group.id == groupVM.currentGroup?.id
        return HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: AppTheme.rTiny)
                    .fill(AppTheme.primary.opacity(0.15))
                    .frame(width: 42, height: 42)
                Text("🏠").font(.system(size: 22))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(group.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.text)
                Text("\(group.memberCount)人のメンバー")
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textSec)
            }
            Spacer()
            Image(systemName: isSelected ? "checkmark" : "chevron.right")
                .font(.system(size: isSelected ? 14 : 13, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? AppTheme.primary : AppTheme.textTer)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(isSelected ? AppTheme.soft : AppTheme.surface)
    }

    private var noGroupsPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.textTer)
            Text("グループがありません")
                .font(.system(size: 16))
                .foregroundStyle(AppTheme.textSec)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var joinGroupButton: some View {
        Button { showJoinGroup = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 15, weight: .medium))
                Text("招待コードで参加")
                    .font(.system(size: 16, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(AppTheme.soft)
            .foregroundStyle(AppTheme.softText)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.rCard))
        }
    }

    private var createGroupButton: some View {
        Button { showCreateGroup = true } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .medium))
                Text("新しいグループ")
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

    private var createGroupSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("グループ名")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textSec)
                    TextField("例: 山田家、職場の買い出し", text: $newGroupName)
                        .font(.system(size: 16))
                        .padding(.horizontal, 14)
                        .frame(height: 50)
                        .background(AppTheme.fieldBg)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.rField))
                }
                Spacer()
                Button {
                    Task {
                        isProcessing = true
                        sheetError = nil
                        do {
                            try await groupVM.createGroup(name: newGroupName)
                            isProcessing = false
                            showCreateGroup = false
                            newGroupName = ""
                        } catch {
                            isProcessing = false
                            sheetError = error.localizedDescription
                        }
                    }
                } label: {
                    Group {
                        if isProcessing {
                            ProgressView().tint(.white)
                        } else {
                            Text("グループを作成")
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(AppTheme.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.rBtn))
                }
                .disabled(newGroupName.trimmingCharacters(in: .whitespaces).isEmpty || isProcessing)
            }
            .padding(20)
            .background(AppTheme.bg)
            .navigationTitle("グループを作成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { showCreateGroup = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var joinGroupSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("招待コード")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textSec)
                    TextField("例: ABCD12", text: $inviteCode)
                        .font(.system(size: 20, design: .monospaced))
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .padding(.horizontal, 14)
                        .frame(height: 50)
                        .background(AppTheme.fieldBg)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.rField))
                }

                if let err = sheetError {
                    Text(err)
                        .font(.system(size: 13))
                        .foregroundStyle(.red)
                }

                Spacer()

                Button {
                    Task {
                        isProcessing = true
                        sheetError = nil
                        do {
                            try await groupVM.joinGroup(inviteCode: inviteCode)
                            isProcessing = false
                            showJoinGroup = false
                            inviteCode = ""
                            dismiss()
                        } catch {
                            isProcessing = false
                            sheetError = error.localizedDescription
                        }
                    }
                } label: {
                    Group {
                        if isProcessing {
                            ProgressView().tint(.white)
                        } else {
                            Text("参加する")
                                .font(.system(size: 17, weight: .semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(AppTheme.primary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.rBtn))
                }
                .disabled(inviteCode.trimmingCharacters(in: .whitespaces).isEmpty || isProcessing)
            }
            .padding(20)
            .background(AppTheme.bg)
            .navigationTitle("招待コードで参加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        showJoinGroup = false
                        inviteCode = ""
                        sheetError = nil
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
