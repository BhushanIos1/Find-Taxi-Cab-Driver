//
//  PhoneHelper.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 01/03/26.
//

import UIKit

struct PhoneHelper {

    static func call(_ number: String) {

        let cleanNumber = number.replacingOccurrences(of: " ", with: "")

        guard let url = URL(string: "tel://\(cleanNumber)"),
              UIApplication.shared.canOpenURL(url)
        else { return }

        UIApplication.shared.open(url)
    }
}
