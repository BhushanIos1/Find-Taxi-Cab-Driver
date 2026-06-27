//
//  DriverDetailsModel.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 27/06/26.
//

import Foundation

struct DriverDetailsResponse: Decodable {

    let result: String
    let message: String?
    let driverData: Driver?

    enum CodingKeys: String, CodingKey {
        case result
        case message
        case driverData = "driver_data"
    }
}
