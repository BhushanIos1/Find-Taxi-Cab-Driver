//
//  NotificationPayload.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 24/08/26.
//

import Foundation

struct NotificationPayload {

    let status: NotificationStatus

    /// Exactly what the server sent, kept for the log line when `status` comes
    /// out `.unknown` — otherwise an unrecognised push is indistinguishable
    /// from no push at all.
    let rawStatus: String?

    let bookingId: String?
    let title: String?
    let message: String?

    init(userInfo: [AnyHashable: Any]) {

        let statusString = Self.stringValue(in: userInfo, keys: "status", "tag")
        self.rawStatus = statusString
        self.status = NotificationStatus(value: statusString)

        self.bookingId = Self.stringValue(in: userInfo, keys: "booking_id", "book_id")

        self.title = Self.stringValue(in: userInfo, keys: "title")
            ?? (userInfo["aps"] as? [String: Any])
                .flatMap { $0["alert"] as? [String: Any] }?["title"] as? String
            ?? (userInfo["aps"] as? [String: Any])?["alert"] as? String

        self.message = Self.stringValue(in: userInfo, keys: "message", "body")
            ?? (userInfo["aps"] as? [String: Any])
                .flatMap { $0["alert"] as? [String: Any] }?["body"] as? String

        #if DEBUG
        print("""

        🔎 NotificationPayload parsed from raw userInfo:
           raw keys: \(userInfo.keys.map { "\($0)" })
           → status: \(statusString ?? "nil") → \(status)
           → bookingId: \(bookingId ?? "nil")
           → title: \(title ?? "nil")
           → message: \(message ?? "nil")

        """)
        #endif
    }
}

private extension NotificationPayload {

    /// APNs custom keys arrive however the backend serialized them — a driver ID or
    /// booking ID sent as a JSON number decodes to `NSNumber`, not `String`, so a
    /// plain `as? String` cast silently fails and the value reads as nil even though
    /// the key is right there. This tries each key in order and accepts either shape.
    static func stringValue(in userInfo: [AnyHashable: Any], keys: String...) -> String? {

        for key in keys {

            guard let value = userInfo[key] else { continue }

            if let string = value as? String, !string.isEmpty {
                return string
            }

            if let number = value as? NSNumber {
                return number.stringValue
            }
        }

        return nil
    }
}
