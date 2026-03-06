//
//  SideMenuRow.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 01/03/26.
//

import SwiftUI

enum SideMenuRowType: Int, CaseIterable {
    case jobHistory
    case paymentHistory
    case bankDetails
    case profile
    case changePassword
    case emergency
    case bookingPage
    case logout
    
    var title: String {
        switch self {
        case .jobHistory: return "Job History"
        case .paymentHistory: return "Payment History"
        case .bankDetails: return "Bank Details"
        case .profile: return "Profile"
        case .changePassword: return "Change Password"
        case .emergency: return "Emergency"
        case .bookingPage: return "Booking Page"
        case .logout: return "Logout"
        }
    }
    
    var iconName: String {
        
        switch self {
        case .jobHistory: return "clock.arrow.trianglehead.counterclockwise.rotate.90"
        case .paymentHistory: return "creditcard"
        case .bankDetails: return "building.columns.fill"
        case .profile: return "person.fill"
        case .changePassword: return "exclamationmark.lock.fill"
        case .emergency: return "phone.fill"
        case .bookingPage: return "book.closed.fill"
        case .logout: return "rectangle.portrait.and.arrow.right"
        }
    }
}
