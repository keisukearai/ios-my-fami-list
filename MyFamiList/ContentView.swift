//
//  ContentView.swift
//  MyFamiList
//
//  Created by keisuke arai on 2026/06/03.
//

import SwiftUI

struct ContentView: View {
    @Environment(AuthViewModel.self) private var authVM

    var body: some View {
        ZStack {
            AppTheme.bg.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "cart.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AppTheme.primary)
                Text("ログイン済み")
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.text)
                if let user = authVM.currentUser {
                    Text(user.displayName.isEmpty ? user.uid : user.displayName)
                        .foregroundStyle(AppTheme.textSec)
                }
                Button("サインアウト") { authVM.signOut() }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.primary)
            }
        }
    }
}

#Preview {
    ContentView()
        .environment(AuthViewModel())
}
