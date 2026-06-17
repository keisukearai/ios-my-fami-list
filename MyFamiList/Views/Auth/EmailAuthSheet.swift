import SwiftUI

struct EmailAuthSheet: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss

    @State private var isLogin = true
    @State private var email = ""
    @State private var password = ""
    @State private var localError: String?
    @State private var showPasswordReset = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        modePicker
                        fieldsSection
                        submitButton
                        if isLogin {
                            forgotPasswordButton
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                }
            }
            .navigationTitle(isLogin ? String(localized: "Sign In with Email") : String(localized: "Sign Up"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
            }
            .disabled(authVM.isLoading)
            .overlay {
                if authVM.isLoading {
                    ProgressView()
                        .padding(20)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .sheet(isPresented: $showPasswordReset) {
                PasswordResetSheet()
            }
            .onChange(of: authVM.isAuthenticated) { _, authenticated in
                if authenticated { dismiss() }
            }
        }
    }

    private var modePicker: some View {
        Picker(String(localized: "Mode"), selection: $isLogin) {
            Text("Sign In").tag(true)
            Text("Sign Up").tag(false)
        }
        .pickerStyle(.segmented)
        .onChange(of: isLogin) { _, _ in
            localError = nil
            authVM.errorMessage = nil
        }
    }

    private var fieldsSection: some View {
        VStack(spacing: 12) {
            if let error = localError ?? authVM.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(spacing: 0) {
                TextField(String(localized: "Email Address"), text: $email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding(14)
                    .accessibilityIdentifier("emailAuthEmailField")
                Divider()
                SecureField(String(localized: "Password (8+ characters)"), text: $password)
                    .textContentType(isLogin ? .password : .newPassword)
                    .padding(14)
                    .accessibilityIdentifier("emailAuthPasswordField")
            }
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.rCard))
            .cardShadow()
        }
    }

    private var submitButton: some View {
        Button {
            Task { await submit() }
        } label: {
            Text(isLogin ? String(localized: "Sign In") : String(localized: "Register"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(AppTheme.primary)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.rBtn))
        }
        .accessibilityIdentifier("emailAuthSubmitButton")
    }

    private var forgotPasswordButton: some View {
        Button(String(localized: "Forgot your password?")) {
            showPasswordReset = true
        }
        .font(.system(size: 14))
        .foregroundStyle(AppTheme.textSec)
    }

    private func submit() async {
        localError = nil
        authVM.errorMessage = nil
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            localError = String(localized: "Please enter your email and password")
            return
        }
        if isLogin {
            await authVM.emailLogin(email: trimmedEmail, password: password)
        } else {
            await authVM.emailRegister(email: trimmedEmail, password: password)
        }
    }
}

// MARK: - Password Reset Sheet

struct PasswordResetSheet: View {
    @Environment(AuthViewModel.self) private var authVM
    @Environment(\.dismiss) private var dismiss

    enum Step { case inputEmail, inputCode, done }

    @State private var step: Step = .inputEmail
    @State private var email = ""
    @State private var code = ""
    @State private var newPassword = ""
    @State private var errorMessage: String?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.bg.ignoresSafeArea()

                VStack(spacing: 24) {
                    switch step {
                    case .inputEmail: emailStep
                    case .inputCode: codeStep
                    case .done: doneStep
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
            }
            .navigationTitle(String(localized: "Reset Password"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { dismiss() }
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

    private var emailStep: some View {
        VStack(spacing: 20) {
            Text("We'll send a confirmation code to your registered email address.")
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.textSec)
                .multilineTextAlignment(.center)

            if let error = errorMessage {
                Text(error).font(.caption).foregroundStyle(.red).frame(maxWidth: .infinity, alignment: .leading)
            }

            TextField(String(localized: "Email Address"), text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding(14)
                .background(AppTheme.surface)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.rCard))
                .cardShadow()

            Button {
                Task { await sendCode() }
            } label: {
                Text("Send Code")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(AppTheme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.rBtn))
            }
        }
    }

    private var codeStep: some View {
        VStack(spacing: 20) {
            Text(String(format: String(localized: "Enter the 6-digit code sent to %@."), email))
                .font(.system(size: 15))
                .foregroundStyle(AppTheme.textSec)
                .multilineTextAlignment(.center)

            if let error = errorMessage {
                Text(error).font(.caption).foregroundStyle(.red).frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(spacing: 0) {
                TextField(String(localized: "Confirmation code (6 digits)"), text: $code)
                    .keyboardType(.numberPad)
                    .padding(14)
                Divider()
                SecureField(String(localized: "New password (8+ characters)"), text: $newPassword)
                    .textContentType(.newPassword)
                    .padding(14)
            }
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.rCard))
            .cardShadow()

            Button {
                Task { await confirmReset() }
            } label: {
                Text("Reset Password")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(AppTheme.primary)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.rBtn))
            }
        }
    }

    private var doneStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(AppTheme.primary)
            Text("Password Reset Complete")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AppTheme.text)
            Button(String(localized: "Close")) { dismiss() }
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity).frame(height: 54)
                .background(AppTheme.primary)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.rBtn))
        }
    }

    private func sendCode() async {
        errorMessage = nil
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { errorMessage = String(localized: "Please enter your email address"); return }
        isLoading = true
        defer { isLoading = false }
        do {
            try await authVM.requestPasswordReset(email: trimmed)
            step = .inputCode
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func confirmReset() async {
        errorMessage = nil
        guard !code.isEmpty, newPassword.count >= 8 else {
            errorMessage = String(localized: "Please enter the code and new password (8+ characters)")
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            try await authVM.confirmPasswordReset(email: email, token: code, newPassword: newPassword)
            step = .done
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
