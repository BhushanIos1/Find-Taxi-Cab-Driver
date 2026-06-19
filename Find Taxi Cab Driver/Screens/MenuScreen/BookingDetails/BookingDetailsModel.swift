//
//  BookingDetailsModel.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 07/03/26.
//

import SwiftUI

struct DriverLastBookingResponse: Decodable {

    let result: String
    let message: String?
    let lastBook: BookingDetailsModel?

    enum CodingKeys: String, CodingKey {
        case result
        case message
        case lastBook = "last_book"
    }
}

struct DriverBookingListResponse: Decodable {

    let result: String
    let message: String?
    let bookingData: [BookingDetailsModel]?

    enum CodingKeys: String, CodingKey {
        case result
        case message
        case bookingData = "booking_data"
    }
}

struct BookingDetailsModel: Identifiable, Decodable {

    let id = UUID()

    let status: String?
    let bookingId: String?
    let customerMobile: String?
    let pickup: String?
    let drop: String?
    let bookingDate: String?
    let bookingStatus: String?

    enum CodingKeys: String, CodingKey {
        case status
        case bookingId = "booking_id"
        case customerMobile = "customer_mobile"
        case pickup
        case drop
        case bookingDate = "booking_date"
        case bookingStatus = "booking_status"
    }
}
