//
//  HistoryModel.swift
//  Find Taxi Cab
//
//  Created by Bhushan Kumar on 01/03/26.
//

import SwiftUI

/// `POST /driver_book_list` — `{driver_id}`.
///
/// Android's `JobHistoryList` declares only `booking_data` and checks it for nil
/// rather than reading a `result` flag, so those are optional here too: a response
/// without them still decodes rather than throwing the whole list away.
struct JobHistoryResponse: Decodable {

    let result: String?
    let message: String?
    let bookingData: [JobHistoryModel]?

    enum CodingKeys: String, CodingKey {
        case result
        case message
        case error
        case bookingData = "booking_data"
    }

    init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)

        result = try container.decodeIfPresent(String.self, forKey: .result)

        // This backend reports success under `message` and failure under `error`.
        message = try container.decodeIfPresent(String.self, forKey: .message)
            ?? container.decodeIfPresent(String.self, forKey: .error)

        bookingData = try container.decodeIfPresent([JobHistoryModel].self, forKey: .bookingData)
    }
}

/// One row of job history. Field names taken from Android's `JobHistory` model.
struct JobHistoryModel: Identifiable, Decodable {

    let id = UUID()

    let bookingId: String?
    let assignStatus: String?
    let date: String?
    let time: String?
    let pickup: String?
    let drop: String?
    let paymentMethod: String?
    let baseFare: String?
    let specialMessage: String?
    let specialNeed: String?

    enum CodingKeys: String, CodingKey {
        case bookingId = "booking_id"
        case assignStatus = "assign_status"
        case date
        case time
        case pickup = "source_addr"
        case drop = "destination_addr"
        case paymentMethod = "payment_method"
        case baseFare = "base_fair"
        case specialMessage = "manual_msg"
        case specialNeed = "special_need"
    }

    /// Hand-rolled for the same reason `BookingData` is: `booking_id` and
    /// `base_fair` commonly arrive as bare JSON numbers, and a plain `String?`
    /// decode throws on those — taking the entire history list down with it.
    init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)

        bookingId = container.flexibleString(.bookingId)
        assignStatus = container.flexibleString(.assignStatus)
        date = container.flexibleString(.date)
        time = container.flexibleString(.time)
        pickup = container.flexibleString(.pickup)
        drop = container.flexibleString(.drop)
        paymentMethod = container.flexibleString(.paymentMethod)
        baseFare = container.flexibleString(.baseFare)
        specialMessage = container.flexibleString(.specialMessage)
        specialNeed = container.flexibleString(.specialNeed)
    }

    /// Memberwise init kept for previews and mock rows.
    init(
        bookingId: String?,
        assignStatus: String?,
        date: String?,
        time: String?,
        pickup: String?,
        drop: String?,
        paymentMethod: String?,
        baseFare: String?,
        specialMessage: String?,
        specialNeed: String?
    ) {
        self.bookingId = bookingId
        self.assignStatus = assignStatus
        self.date = date
        self.time = time
        self.pickup = pickup
        self.drop = drop
        self.paymentMethod = paymentMethod
        self.baseFare = baseFare
        self.specialMessage = specialMessage
        self.specialNeed = specialNeed
    }
}

extension JobHistoryModel {

    /// Same labels Android's `JobHistoryAdapter` switch produces, including its
    /// fallback of showing the raw status for anything unrecognised.
    var statusDisplay: String {

        switch assignStatus?.lowercased() {

        case "complete":     return "Completed"
        case "abandon":      return "Abandoned"
        case "cancel":       return "Cancelled"
        case "assigned":     return "Assigned"
        case "accept":       return "Accepted"
        case "pickcustomer": return "PickCustomer"
        case "onboard":      return "Onboard"
        default:             return assignStatus ?? "—"
        }
    }

    /// Android renders this as `"£ " + base_fair`.
    var fareDisplay: String {
        "£ \(baseFare ?? "0")"
    }
}
