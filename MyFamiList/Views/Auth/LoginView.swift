import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @Environment(AuthViewModel.self) private var authVM
    @State private var showEmailAuth = false

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()

            GeometryReader { geo in
                Circle()
                    .fill(AppTheme.soft)
                    .frame(width: 380, height: 380)
                    .offset(x: -100, y: -80)
                    .opacity(0.65)
                Circle()
                    .fill(AppTheme.soft)
                    .frame(width: 300, height: 300)
                    .offset(x: geo.size.width - 60, y: geo.size.height - 160)
                    .opacity(0.55)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()
                logoArea
                Spacer()

                if let error = authVM.errorMessage {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(.red)
                            .padding(.top, 1)
                            .accessibilityIdentifier("loginErrorIcon")
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.leading)
                            .accessibilityIdentifier("loginErrorText")
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                    .accessibilityIdentifier("loginErrorBanner")
                }

                buttonsArea
                termsText
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
    }

    // MARK: - Logo

    private var logoArea: some View {
        VStack(spacing: 20) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(AppTheme.primary)
                    .frame(width: 84, height: 84)
                    .shadow(color: AppTheme.primary.opacity(0.38), radius: 17, x: 0, y: 8)
                Image(systemName: "cart.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.white)
            }
            VStack(spacing: 10) {
                Text("MyFamiList")
                    .font(.system(size: 33, weight: .bold))
                    .foregroundStyle(AppTheme.text)
                Text(loc("Share shopping lists with family and groups."))
                    .font(.system(size: 15))
                    .foregroundStyle(AppTheme.textSec)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
            }
        }
    }

    // MARK: - Buttons

    private var buttonsArea: some View {
        VStack(spacing: 12) {
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
                request.nonce = authVM.prepareAppleSignIn()
            } onCompletion: { result in
                Task { await authVM.handleAppleSignIn(result: result) }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 54)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.rBtn))

            Button {
                Task { await authVM.signInWithGoogle() }
            } label: {
                HStack(spacing: 10) {
                    googleLogo
                    Text(loc("Continue with Google"))
                        .font(.system(size: 17, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(AppTheme.surface)
                .foregroundStyle(AppTheme.text)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.rBtn))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.rBtn)
                        .stroke(AppTheme.sep, lineWidth: 1)
                )
            }

            Button {
                showEmailAuth = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "envelope")
                        .font(.system(size: 17, weight: .medium))
                    Text(loc("Continue with Email"))
                        .font(.system(size: 17, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(AppTheme.surface)
                .foregroundStyle(AppTheme.text)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.rBtn))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.rBtn)
                        .stroke(AppTheme.sep, lineWidth: 1)
                )
            }

#if DEBUG
            Button {
                Task { await authVM.devLogin() }
            } label: {
                Text("🛠 開発用ログイン")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AppTheme.textSec)
                    .frame(height: 44)
            }
            .accessibilityIdentifier("devLoginButton")
#endif
        }
        .padding(.horizontal, 24)
        .sheet(isPresented: $showEmailAuth) {
            EmailAuthSheet()
                .environment(authVM)
        }
    }

    // MARK: - Google logo placeholder

    private var googleLogo: some View {
        ZStack {
            Circle().fill(Color.white).frame(width: 22, height: 22)
            Text("G")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color(red: 0.26, green: 0.52, blue: 0.96))
        }
    }

    // MARK: - Terms

    private var termsText: some View {
        Text(loc("By continuing, you agree to our Terms of Service and Privacy Policy."))
            .font(.system(size: 11.5))
            .foregroundStyle(AppTheme.textTer)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            .padding(.top, 20)
            .padding(.bottom, 40)
    }
}

#Preview {
    LoginView()
        .environment(AuthViewModel())
}
