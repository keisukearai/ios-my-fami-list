//
//  MyFamiListApp.swift
//  MyFamiList
//
//  Created by keisuke arai on 2026/06/03.
//

import SwiftUI
import GoogleSignIn
import UserNotifications
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async { application.registerForRemoteNotifications() }
        }
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        Task { await APIClient.shared.registerDeviceToken(token) }
    }

    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else { return false }
        return InviteHandler.shared.handle(url: url)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}

@main
struct MyFamiListApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var authVM = AuthViewModel()
    @State private var inviteHandler = InviteHandler.shared
    @State private var purchaseService = PurchaseService()

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
            .environment(inviteHandler)
            .environment(purchaseService)
            .task { await authVM.checkAuth() }
            .onOpenURL { url in
                if !inviteHandler.handle(url: url) {
                    GIDSignIn.sharedInstance.handle(url)
                }
            }
        }
    }
}
