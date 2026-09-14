//
//  NotificationStatus.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 24/08/26.
//

enum NotificationStatus: String {
    
    // Driver
    case booking
    case adminBooking = "admin_booking"
    case bookingCancel = "booking_cancel"
    case blockAccount = "block_account"
    
    case unknown
}

extension NotificationStatus {
    
    init(value: String?) {
        self = NotificationStatus(rawValue: value ?? "") ?? .unknown
    }
}
