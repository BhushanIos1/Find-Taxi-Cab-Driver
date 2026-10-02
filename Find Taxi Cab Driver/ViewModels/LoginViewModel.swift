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
        
    func login(email: String, password: String, router: AppRouter) {
        
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
                
                // Never a placeholder string — an empty token tells the server
                // honestly "none yet" rather than poisoning this account's push
                // registration with a literal value that will never receive
                // anything. See `FCMTokenManager.currentToken()`.
                let fcmToken = await FCMTokenManager.shared.currentToken() ?? ""
                
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
                    AppState.shared.login(driverId: driver.id, token: driver.token, status: driver.workStatus, driverName: driver.driverName, driverTitle: driver.title, email: driver.email)

                    // Session now exists — push the FCM token we already hold.
                    FCMTokenManager.shared.registerWithServerIfLoggedIn()

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
    
    func changePassword(password: String, router: AppRouter) {

        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        let passwordTrimmed = password.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        Task {

            defer { isLoading = false }

            do {

                let response: CommonResponse = try await APIClient.shared.request(
                    DriverAPI.changePassword(
                        password: passwordTrimmed
                    ),
                    responseType: CommonResponse.self
                )

                if response.result == "success" {

                    let message = response.message ?? "Password changed successfully"

                    print("✅ CHANGE PASSWORD:", message)

                    isLoading = false
                    loginState = .success(message)

                } else {

                    let message = response.message ?? "Failed to change password"

                    print("❌ CHANGE PASSWORD FAILED:", message)

                    errorMessage = message
                    loginState = .failure(message)
                }

            } catch {

                print("❌ CHANGE PASSWORD ERROR:", error.localizedDescription)

                errorMessage = error.localizedDescription
                loginState = .failure(error.localizedDescription)
            }
        }
    }
}
