import SwiftUI

struct PasswordChangeSheet: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss

    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var isDone = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()

                VStack(spacing: 24) {
                    if isDone {
                        doneView
                    } else {
                        formView
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
            }
            .navigationTitle(loc("Change Password"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(loc("Cancel")) { dismiss() }
                }
            }
            .disabled(isLoading)
            .overlay {
                if isLoading {
                    ProgressView()
                        .padding(20)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    private var formView: some View {
        VStack(spacing: 20) {
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(spacing: 0) {
                SecureField(loc("Current Password"), text: $currentPassword)
                    .textContentType(.password)
                    .padding(14)
                Divider()
                SecureField(loc("New Password (8+ characters)"), text: $newPassword)
                    .textContentType(.newPassword)
                    .padding(14)
                Divider()
                SecureField(loc("New Password (confirm)"), text: $confirmPassword)
                    .textContentType(.newPassword)
                    .padding(14)
            }
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.rCard))
            .cardShadow()

            Button {
                Task { await submit() }
            } label: {
                Text(loc("Change"))
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(AppTheme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.rBtn))
            }
        }
    }

    private var doneView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.primary)
            Text(loc("Password changed successfully"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppTheme.text)
            Button(loc("Close")) { dismiss() }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity).frame(height: 54)
                .background(AppTheme.primary)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.rBtn))
        }
    }

    private func submit() async {
        errorMessage = nil
        guard !currentPassword.isEmpty, !newPassword.isEmpty else {
            errorMessage = loc("Please fill in all fields")
            return
        }
        guard newPassword.count >= 8 else {
            errorMessage = loc("New password must be at least 8 characters")
            return
        }
        guard newPassword == confirmPassword else {
            errorMessage = loc("Passwords do not match")
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            try await authVM.changePassword(currentPassword: currentPassword, newPassword: newPassword)
            isDone = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
