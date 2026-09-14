//
//  BookingModel.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 15/08/26.
//

import Foundation

struct BookingDetailsResponse: Decodable {

    let result: String
    let bookingData: BookingData?
    let error: String?

    enum CodingKeys: String, CodingKey {
        case result
        case bookingData = "booking_data"
        case error
    }
}

/// `/driver_last_book` — the driver's most recent booking, used to restore an
/// in-progress trip after the app was killed. Decodes into `BookingData` because
/// `last_book` carries exactly the same field names `get_bookdata` does
/// (`booking_id`, `source_addr`, `latfrom`, `cus_mob`, `assign_status`, …), which
/// is what Android reads in `BookingPage.getBookingStatus()`.
struct DriverActiveBookingResponse: Decodable {

    let result: String
    let message: String?
    let lastBook: BookingData?

    enum CodingKeys: String, CodingKey {
        case result
        case message
        case lastBook = "last_book"
    }
}

struct BookingData: Decodable, Equatable {

    let bookingId: String?
    let pickupAddress: String?
    let dropAddress: String?
    let bookingDate: String?
    let bookingTime: String?
    let bookingStatus: String?

    /// `added_on` — when the booking was placed. `driver_last_book` returns it and
    /// Android's Booking Page shows it as "Booking Date"; `get_bookdata` doesn't
    /// send it, hence optional like everything else here.
    let addedOn: String?

    let customerName: String?
    let customerPhone: String?

    // New-booking-offer fields — parameter names confirmed against the Android
    // client's getBookData()/autoAccept() (`object.getString("source_addr")`, etc.),
    // since this endpoint is shared by both platforms.
    let specialNeed: String?
    let manualMessage: String?
    let latFrom: String?
    let longiFrom: String?
    let latTo: String?
    let longiTo: String?

    let driverId: String?
    let driverName: String?
    let driverPhone: String?
    let driverPhoto: String?

    let vehicleNumber: String?
    let vehicleModel: String?
    let vehicleMake: String?

    enum CodingKeys: String, CodingKey {

        case bookingId = "booking_id"
        case pickupAddress = "source_addr"
        case dropAddress = "destination_addr"
        case bookingDate = "date"
        case bookingTime = "time"
        case bookingStatus = "assign_status"
        case addedOn = "added_on"

        case customerName = "cust_name"
        case customerPhone = "cus_mob"

        case specialNeed = "special_need"
        case manualMessage = "manual_msg"
        case latFrom = "latfrom"
        case longiFrom = "longifrom"
        case latTo = "latto"
        case longiTo = "longto"

        case driverId = "driver_id"
        case driverName = "driverName"
        case driverPhone = "contact_no"
        case driverPhoto = "driver_photo"

        case vehicleNumber = "vehicle_no"
        case vehicleModel = "vehicle_model"
        case vehicleMake = "vehicle_make"
    }

    /// Hand-rolled so a single number-shaped field can't take the whole booking
    /// down. Every property here is `String?`, but `booking_id`, the four
    /// lat/lng values and `cus_mob` are all routinely serialized as bare JSON
    /// numbers. With the synthesized decoder, one of those throws `typeMismatch`,
    /// the entire `BookingData` fails to decode, `bookingDetails` never gets set —
    /// and the ride-offer popup silently never opens.
    init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)

        bookingId = container.flexibleString(.bookingId)
        pickupAddress = container.flexibleString(.pickupAddress)
        dropAddress = container.flexibleString(.dropAddress)
        bookingDate = container.flexibleString(.bookingDate)
        bookingTime = container.flexibleString(.bookingTime)
        bookingStatus = container.flexibleString(.bookingStatus)
        addedOn = container.flexibleString(.addedOn)

        customerName = container.flexibleString(.customerName)
        customerPhone = container.flexibleString(.customerPhone)

        specialNeed = container.flexibleString(.specialNeed)
        manualMessage = container.flexibleString(.manualMessage)
        latFrom = container.flexibleString(.latFrom)
        longiFrom = container.flexibleString(.longiFrom)
        latTo = container.flexibleString(.latTo)
        longiTo = container.flexibleString(.longiTo)

        driverId = container.flexibleString(.driverId)
        driverName = container.flexibleString(.driverName)
        driverPhone = container.flexibleString(.driverPhone)
        driverPhoto = container.flexibleString(.driverPhoto)

        vehicleNumber = container.flexibleString(.vehicleNumber)
        vehicleModel = container.flexibleString(.vehicleModel)
        vehicleMake = container.flexibleString(.vehicleMake)
    }
}

extension KeyedDecodingContainer {

    /// Reads a value that the backend may send either quoted or as a raw number,
    /// returning nil rather than throwing when it's missing, null, or neither.
    func flexibleString(_ key: Key) -> String? {

        if let value = try? decodeIfPresent(String.self, forKey: key) {
            return value
        }

        if let value = try? decodeIfPresent(Int.self, forKey: key) {
            return String(value)
        }

        if let value = try? decodeIfPresent(Double.self, forKey: key) {
            return String(value)
        }

        return nil
    }
}

