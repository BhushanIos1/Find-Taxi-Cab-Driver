//
//  NotificationManager.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 24/08/26.
//

import Foundation
import UserNotifications

/// Single entry point for every inbound push, whatever state the app was in when it
/// arrived — the iOS equivalent of the Android app's `MyFirebaseMessagingService` +
/// its `INTENT_FILTER` local broadcast rolled into one. `AppDelegate` forwards every
/// remote notification callback here; screens observe `pendingNotification` instead
/// of talking to push APIs directly.
final class NotificationManager: NSObject, ObservableObject {

    static let shared = NotificationManager()

    @Published var pendingNotification: NotificationPayload?

    private override init() {
        super.init()
    }

    func handle(userInfo: [AnyHashable: Any]) {

        let payload = NotificationPayload(
            userInfo: userInfo
        )

        print("""

        🔔 PUSH NOTIFICATION
        =========================
        Status: \(payload.status)
        Booking ID: \(payload.bookingId ?? "nil")
        Title: \(payload.title ?? "nil")
        Message: \(payload.message ?? "nil")
        =========================

        """)

        presentLocalAlertIfNeeded(for: payload, rawUserInfo: userInfo)

        DispatchQueue.main.async {
            self.pendingNotification = payload
        }
    }
}

private extension NotificationManager {

    /// The backend sends silent/background pushes (`content-available` only, no
    /// `aps.alert`) so status-driven pushes can wake the app even when it's backgrounded
    /// — same reason the Android app sends FCM *data* messages instead of *notification*
    /// messages. iOS won't show anything for a silent push on its own, so — exactly like
    /// `MyFirebaseMessagingService.sendNotification()` on Android — the app builds its
    /// own heads-up alert from the payload's `title`/`message`.
    func presentLocalAlertIfNeeded(for payload: NotificationPayload, rawUserInfo: [AnyHashable: Any]) {

        let alreadyDisplayedBySystem = (rawUserInfo["aps"] as? [String: Any])?["alert"] != nil

        guard !alreadyDisplayedBySystem,
              let title = payload.title,
              let body = payload.message else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = rawUserInfo

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }
}

extension NotificationManager {
    
    func driverAction(
        for payload: NotificationPayload
    ) -> DriverNotificationAction {
        
        switch payload.status {
            
        case .booking,
             .adminBooking:
            
            return .newBooking
            
        case .bookingCancel:
            
            return .customerCancelled
            
        case .blockAccount:
            
            return .accountBlocked
            
        default:
            
            return .none
        }
    }
}
