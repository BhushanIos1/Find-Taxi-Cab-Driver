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

    case unknown
}

extension NotificationStatus {

    /// The API doc documents the blocked-account status as `block_account`, but the
    /// Android client compares against `"block"` (`R.string.block_status`) and would
    /// ignore `block_account` entirely. Since the two disagree and guessing wrong
    /// means a blocked driver is never told, both spellings are accepted.
    private static let blockedAccountAliases: Set<String> = ["block_account", "block"]

    init(value: String?) {

        let raw = (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if Self.blockedAccountAliases.contains(raw) {
            self = .blockAccount
            return
        }

        self = NotificationStatus(rawValue: raw) ?? .unknown
    }
}

enum DriverNotificationAction {
    
    case newBooking
    case customerCancelled
    case accountBlocked
    case none
}
