//
//  AppRoute.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 26/02/26.
//

import SwiftUI

enum AppRoute: Hashable {

    // Auth Flow
    case registration
    case login
    case forgotPassword

    // Menu App
    case home
    case jobHistory
    case paymentHistory
    case bankDetails
    case profile
    case changePassword
    case emergency
    case booking
}
