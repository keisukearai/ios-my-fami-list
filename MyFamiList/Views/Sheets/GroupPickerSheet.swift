import SwiftUI

struct GroupPickerSheet: View {
    let groupVM: GroupViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(PurchaseService.self) private var purchaseService

    @State private var showCreateGroup = false
    @State private var showJoinGroup = false
    @State private var showPaywall = false
    @State private var newGroupName = ""
    @State private var inviteCode = ""
    @State private var isProcessing = false
    @State private var sheetError: String?
    @State private var showRenameGroup = false
    @State private var renameGroupId: Int? = nil
    @State private var renameGroupText = ""
    @State private var showDeleteGroupConfirm = false
    @State private var pendingDeleteGroupId: Int? = nil
    @State private var showLeaveGroupConfirm = false
    @State private var pendingLeaveGroupId: Int? = nil

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
            .navigationTitle(String(localized: "Manage Groups"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Close")) { dismiss() }
                }
            }
            .sheet(isPresented: $showCreateGroup) { createGroupSheet }
            .sheet(isPresented: $showJoinGroup) { joinGroupSheet }
            .sheet(isPresented: $showPaywall) { PaywallSheet() }
            .alert(String(localized: "Rename Group"), isPresented: $showRenameGroup) {
                TextField(String(localized: "Group name"), text: $renameGroupText)
                Button(String(localized: "Save")) {
                    guard let id = renameGroupId else { return }
                    let name = renameGroupText.trimmingCharacters(in: .whitespaces)
                    guard !name.isEmpty else { return }
                    Task { await groupVM.updateGroup(id: id, name: name) }
                }
                Button(String(localized: "Cancel"), role: .cancel) {}
            }
            .confirmationDialog(String(localized: "Delete this group?"), isPresented: $showDeleteGroupConfirm, titleVisibility: .visible) {
                Button(String(localized: "Delete"), role: .destructive) {
                    guard let id = pendingDeleteGroupId else { return }
                    Task { await groupVM.deleteGroup(id: id); dismiss() }
                }
            }
            .confirmationDialog(String(localized: "Leave this group?"), isPresented: $showLeaveGroupConfirm, titleVisibility: .visible) {
                Button(String(localized: "Leave"), role: .destructive) {
                    guard let id = pendingLeaveGroupId else { return }
                    Task { await groupVM.leaveGroup(id: id); dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .alert(String(localized: "Error"), isPresented: Binding(
            get: { groupVM.errorMessage != nil },
            set: { if !$0 { groupVM.errorMessage = nil } }
        )) {
            Button(String(localized: "OK")) {}
        } message: {
            Text(groupVM.errorMessage ?? "")
        }
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
                .contextMenu {
                    if group.isOwner {
                        Button {
                            renameGroupId = group.id
                            renameGroupText = group.name
                            showRenameGroup = true
                        } label: { Label(String(localized: "Rename Group"), systemImage: "pencil") }
                        Divider()
                        Button(role: .destructive) {
                            pendingDeleteGroupId = group.id
                            showDeleteGroupConfirm = true
                        } label: { Label(String(localized: "Delete Group"), systemImage: "trash") }
                    } else {
                        Button(role: .destructive) {
                            pendingLeaveGroupId = group.id
                            showLeaveGroupConfirm = true
                        } label: { Label(String(localized: "Leave Group"), systemImage: "rectangle.portrait.and.arrow.right") }
                    }
                }

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
                    .fill(isSelected ? AppTheme.soft : AppTheme.fieldBg)
                    .frame(width: 42, height: 42)
                Text("🏠").font(.system(size: 22))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(group.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.text)
                Text(String(format: String(localized: "%d lists · %d members"), group.listCount, group.memberCount))
                    .font(.system(size: 13))
                    .foregroundStyle(AppTheme.textSec)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppTheme.primary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
        .background(isSelected ? AppTheme.soft : AppTheme.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(isSelected ? AppTheme.primary.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }

    private var noGroupsPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3")
                .font(.system(size: 40))
                .foregroundStyle(AppTheme.textTer)
            Text("No groups")
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
                Text("Join with Invite Code")
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
        Button {
            if purchaseService.isPro || groupVM.groups.count < 2 {
                showCreateGroup = true
            } else {
                showPaywall = true
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .medium))
                Text("New Group")
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
                    Text("Group name")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textSec)
                    TextField(String(localized: "e.g. Smith Family, Office Groceries"), text: $newGroupName)
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
                            Text("Create Group")
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
            .navigationTitle(String(localized: "Create Group"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { showCreateGroup = false }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var joinGroupSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Invite code")
                        .font(.system(size: 13))
                        .foregroundStyle(AppTheme.textSec)
                    TextField(String(localized: "e.g. ABCD12"), text: $inviteCode)
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
                            Text("Join")
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
            .navigationTitle(String(localized: "Join with Invite Code"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) {
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
