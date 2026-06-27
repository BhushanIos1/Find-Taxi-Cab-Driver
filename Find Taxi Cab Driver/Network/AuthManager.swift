//
//  AuthManager.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 21/03/26.
//

import SwiftUI

final class AuthManager {
    
    static let shared = AuthManager()
    
    @AppStorage("driverId") var driverId: String = ""
    @AppStorage("token") var token: String = ""
    @AppStorage("workStatus") var workStatus: String = ""
    @AppStorage("driverName") var driverName: String = ""
    @AppStorage("driverTitle") var driverTitle: String = ""
    @AppStorage("email") var email: String = ""
    
    private init() {}
    
    var isLoggedIn: Bool {
        !driverId.isEmpty
    }
    
    func saveLogin(driverId: String, token: String?, status: String?, driverName: String?, driverTitle: String?, email: String?) {
        self.driverId = driverId
        self.token = token ?? ""
        self.workStatus = status ?? ""
        self.driverName = driverName ?? ""
        self.driverTitle = driverTitle ?? ""
        self.email = email ?? ""
    }
    
    func logout() {
        driverId = ""
        token = ""
        workStatus = ""
        driverName = ""
        driverTitle = ""
        email = ""
    }
}
