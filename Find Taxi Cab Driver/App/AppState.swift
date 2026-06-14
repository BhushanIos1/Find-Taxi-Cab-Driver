//
//  AppState.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 21/03/26.
//

import SwiftUI

@MainActor
final class AppState: ObservableObject {
    
    static let shared = AppState()
    
    @Published var isLoggedIn: Bool = false
    
    private init() {
        restoreSession()
    }
    
    func restoreSession() {
        isLoggedIn = AuthManager.shared.isLoggedIn
    }
    
    func login(driverId: String, token: String?, status: String?) {
        AuthManager.shared.saveLogin(driverId: driverId, token: token, status: status)
        isLoggedIn = true
    }
    
    func logout() {
        AuthManager.shared.logout()
        isLoggedIn = false
    }
}
