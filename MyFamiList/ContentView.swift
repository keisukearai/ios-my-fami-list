import SwiftUI

struct ContentView: View {
    @Environment(AuthViewModel.self) private var authVM

    var body: some View {
        if let user = authVM.currentUser {
            MainTabView(user: user, onSignOut: { authVM.signOut() })
        } else {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.bg)
        }
    }
}
