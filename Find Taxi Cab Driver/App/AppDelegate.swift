//
//  AppDelegate.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 04/03/26.
//

import UIKit
import UserNotifications
import IQKeyboardManagerSwift
import IQKeyboardToolbarManager
import GoogleMaps
import FirebaseCore
import FirebaseMessaging
import UserNotifications

class AppDelegate: NSObject,
                   UIApplicationDelegate,
                   UNUserNotificationCenterDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions:
        [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        
        setupNotifications(application)
        
        IQKeyboardManager.shared.isEnabled = true
        IQKeyboardManager.shared.resignOnTouchOutside = true
        IQKeyboardToolbarManager.shared.isEnabled = true
        IQKeyboardToolbarManager.shared.toolbarConfiguration.tintColor = .label
        IQKeyboardToolbarManager.shared.toolbarConfiguration.previousNextDisplayMode = .alwaysShow
        
        GMSServices.provideAPIKey(MapAPIKey.apiKey)
        return true
    }
}

private extension AppDelegate {
    
    func setupNotifications(_ application: UIApplication) {
        
        UNUserNotificationCenter.current().delegate = self
        
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { granted, error in
            print("Permission granted: \(granted)")
            
            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }
    }
}

extension AppDelegate {
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        
        Messaging.messaging().apnsToken = deviceToken
        
        print("✅ APNS Token Received")
        
        Messaging.messaging().token { token, error in
            
            if let token {
                print("🔥 FCM Token:", token)
                FCMTokenManager.shared.updateToken(token)
            }
            
            if let error {
                print("❌ FCM Error:", error)
            }
        }
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("❌ APNS Registration Failed:", error)
    }
}

extension AppDelegate: MessagingDelegate {
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else { return }
        
        print("Updated FCM Token: \(token)")
        
        // ✅ Single source of truth
        FCMTokenManager.shared.updateToken(token)
    }
}

extension AppDelegate {

    /// Data-only / silent pushes (`content-available`, no `aps.alert`) land here in
    /// every app state — foreground, background, or freshly launched from a push.
    /// This is the direct counterpart of `MyFirebaseMessagingService.onMessageReceived()`
    /// on Android, which is why almost every status-driven push (`booking`,
    /// `booking_cancel`, `block`) is sent silent rather than as a visible alert.
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        print("🔔📡 didReceiveRemoteNotification (silent/background path) — raw payload:", userInfo)
        NotificationManager.shared.handle(userInfo: userInfo)
        completionHandler(.newData)
    }

    /// Fires only for pushes that carry a visible `aps.alert` while the app is in the
    /// foreground (e.g. a combined notification+data payload).
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        print("🔔📱 willPresent (foreground, visible alert) — raw payload:", notification.request.content.userInfo)
        NotificationManager.shared.handle(userInfo: notification.request.content.userInfo)
        completionHandler([.banner, .list, .sound])
    }

    /// User tapped a visible notification (banner or from Notification Center).
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        print("🔔👆 didReceive response (user tapped) — raw payload:", response.notification.request.content.userInfo)
        NotificationManager.shared.handle(userInfo: response.notification.request.content.userInfo, wasTapped: true)
        completionHandler()
    }
}

struct MapAPIKey {
    static let apiKey = "AIzaSyAu8-FoJEb1KdqY5ZBBSFoIGx_FMCcYgvo"
    static let directionApiKey = "AIzaSyA9hS0Vp12mgfr3xLU1kVk7Gg-Q8cgWraE"
}
