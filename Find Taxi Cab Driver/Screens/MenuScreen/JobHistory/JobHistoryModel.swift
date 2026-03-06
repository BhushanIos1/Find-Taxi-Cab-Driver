//
//  HistoryModel.swift
//  Find Taxi Cab
//
//  Created by Bhushan Kumar on 01/03/26.
//

import SwiftUI

struct JobHistoryModel: Identifiable {
    
    let id = UUID()
    
    let status: String
    let jobNumber: String
    let jobDate: String
    let time: String
    let pickup: String
    let drop: String
    let paymentMode: String
    let specialMessage: String
    let specialNeed: String
    let fare: String
}
