//
//  NotificationStatus.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 24/08/26.
//

/// Mirrors the `status` (or `tag`) values the backend sends in the FCM/APNs data
/// payload, per the API documentation's driver-facing set.
enum NotificationStatus: String {

    // Driver
    case booking
    case adminBooking = "admin_booking"
    case bookingCancel = "booking_cancel"
    case blockAccount = "block_account"

    /// A new chat message. The API collection says `send_message` "pushes an FCM
    /// notification to the other party" but never names the status it carries,
    /// so every plausible spelling is matched — see `chatAliases`.
    case chatMessage

    case unknown
}

extension NotificationStatus {

    /// The API doc documents the blocked-account status as `block_account`, but the
    /// Android client compares against `"block"` (`R.string.block_status`) and would
    /// ignore `block_account` entirely. Since the two disagree and guessing wrong
    /// means a blocked driver is never told, both spellings are accepted.
    private static let blockedAccountAliases: Set<String> = ["block_account", "block"]

    /// Undocumented, so matched generously. An unrecognised status becomes
    /// `.unknown` and is silently dropped, which is exactly how a chat push ends
    /// up doing nothing at all.
    private static let chatAliases: Set<String> = [
        "chat", "chat_message", "chatmessage", "chat_msg",
        "new_message", "newmessage", "new_chat", "message"
    ]

    init(value: String?) {

        let raw = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if Self.blockedAccountAliases.contains(raw) {
            self = .blockAccount
            return
        }

        if Self.chatAliases.contains(raw) {
            self = .chatMessage
            return
        }

        self = NotificationStatus(rawValue: raw) ?? .unknown
    }
}

enum DriverNotificationAction {

    case newBooking

    /// `admin_booking` — fetched via `/booking` (no params, resolves the
    /// authenticated driver's pending admin offer) rather than `/get_bookdata`.
    case newAdminBooking

    case customerCancelled
    case accountBlocked
    case none
}
