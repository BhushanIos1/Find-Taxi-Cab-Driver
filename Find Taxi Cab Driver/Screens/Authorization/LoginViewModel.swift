//
//  LoginViewModel.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 12/04/26.
//

import SwiftUI

enum LoginState: Equatable {
    case success(String)
    case failure(String)
}

@MainActor
final class LoginViewModel: ObservableObject {
    
    @Published var isLoading = false
    @Published var loginState: LoginState?
    
    private var isRequestInProgress = false
    
    @Published var errorMessage: String?
    @Published var userData: Driver?
        
    func login(
        email: String,
        password: String,
        router: AppRouter
    ) {
        guard !isRequestInProgress else {
            print("⛔️ Request already in progress")
            return
        }
        
        isRequestInProgress = true
        isLoading = true
        
        // ✅ Trim inputs
        let emailTrimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let passwordTrimmed = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        Task {
            
            defer {
                isLoading = false
                isRequestInProgress = false
            }
            
            do {
                
                let fcmToken = FCMTokenManager.shared.getToken() ?? "FIREBASE_FCM_TOKEN"
                
                let response: LoginResponse = try await APIClient.shared.request(
                    DriverAPI.login(
                        email: emailTrimmed,
                        password: passwordTrimmed,
                        token: fcmToken
                    ),
                    responseType: LoginResponse.self
                )
                
                if response.result == "success", let driver = response.driver_data {
                    
                    print("✅ LOGIN SUCCESS:", driver.id)
                    AppState.shared.login(driverId: driver.id, token: driver.token, status: driver.workStatus)
                    loginState = .success("Login Successful")
                    
                } else {
                    
                    let message = response.error ?? "Invalid login response"
                    print("❌ LOGIN FAILED:", message)
                    
                    loginState = .failure(message)
                }
            } catch {
                print("❌ LOGIN ERROR:", error.localizedDescription)
                loginState = .failure(error.localizedDescription)
            }
        }
    }
}
