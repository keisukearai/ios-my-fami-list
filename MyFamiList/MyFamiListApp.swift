//
//  MyFamiListApp.swift
//  MyFamiList
//
//  Created by keisuke arai on 2026/06/03.
//

import SwiftUI
import GoogleSignIn

@main
struct MyFamiListApp: App {
    @State private var authVM = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            Group {
                if authVM.isAuthenticated {
                    ContentView()
                } else {
                    LoginView()
                }
            }
            .environment(authVM)
            .task { await authVM.checkAuth() }
            .onOpenURL { GIDSignIn.sharedInstance.handle($0) }
        }
    }
}
