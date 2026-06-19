//
//  UpdateProfileViewModel.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 14/06/26.
//

import SwiftUI
import UIKit

@MainActor
final class ProfileViewModel: ObservableObject {

    @Published var isSuccess = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var registrationState: RegistrationState?

    func updateProfile(
        driverName: String,
        contactNo: String,
        address: String,
        bankAccountNumber: String,
        driverPhoto: UIImage?
    ) {

        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        Task {

            defer { isLoading = false }

            do {

                let base64Image = driverPhoto?.toBase64()
                
                print("""
                📸 IMAGE BASE64 LENGTH:
                \(base64Image?.count ?? 0)

                Driver ID:
                \(AuthManager.shared.driverId)
                """)

                let response: CommonResponse = try await APIClient.shared.request(
                    DriverAPI.updateProfile(
                        driverName: driverName,
                        contactNo: contactNo,
                        address: address,
                        bankAccountNumber: bankAccountNumber,
                        driverPhoto: base64Image
                    ),
                    responseType: CommonResponse.self
                )

                if response.result == "success" {

                    let message = response.message ?? "Profile Updated"

                    print("✅ PROFILE UPDATED:", message)

                    isSuccess = true
                    registrationState = .success(message)

                } else {

                    let message = response.message ?? "Failed To Update"

                    print("❌ PROFILE UPDATE FAILED:", message)

                    errorMessage = message
                    registrationState = .failure(message)
                }

            } catch {

                print("❌ PROFILE UPDATE ERROR:", error)

                errorMessage = error.localizedDescription
                registrationState = .failure(error.localizedDescription)
            }
        }
    }
}
