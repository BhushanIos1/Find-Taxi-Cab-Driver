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

    /// Set only when the user *taps* a chat notification — the booking whose
    /// thread should open. A push that merely arrives must not yank anyone out
    /// of what they were doing, so background deliveries never write this.
    @Published var chatToOpen: String?

    private override init() {
        super.init()
    }

    /// - Parameter wasTapped: true when the user opened the app from the
    ///   notification itself, which is the only case that should navigate.
    func handle(userInfo: [AnyHashable: Any], wasTapped: Bool = false) {

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
        Was tapped: \(wasTapped)
        Raw: \(userInfo)
        =========================

        """)

        if payload.status == .unknown {
            // Names the value so an unhandled push can be identified rather than
            // disappearing without trace.
            print("⚠️ UNHANDLED PUSH STATUS: \(payload.rawStatus ?? "none")")
        }

        presentLocalAlertIfNeeded(for: payload, rawUserInfo: userInfo)

        DispatchQueue.main.async {

            self.pendingNotification = payload

            guard wasTapped,
                  payload.status == .chatMessage,
                  let bookingId = payload.bookingId,
                  !bookingId.isEmpty else {
                return
            }

            print("💬 Opening chat for booking \(bookingId) from a tapped notification")
            self.chatToOpen = bookingId
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
