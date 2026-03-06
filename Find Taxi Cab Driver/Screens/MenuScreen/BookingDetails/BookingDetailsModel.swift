//
//  BookingDetailsModel.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 07/03/26.
//

import SwiftUI

struct BookingDetailsModel: Identifiable {
    
    let id = UUID()
    
    let status: String
    let bookingId: String
    let customerMobile: String
    let pickup: String
    let drop: String
    let bookingDate: String
    let bookingStatus: String
}

