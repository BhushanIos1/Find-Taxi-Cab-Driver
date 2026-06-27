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
    
    @Published var driver: Driver?
    
    func updateProfile(driverName: String, driverPhoto: UIImage?) {

        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        Task {

            defer { isLoading = false }

            do {

                let response = try await APIClient.shared.uploadProfile(
                    driverName: driverName,
                    driverPhoto: driverPhoto
                )

                if response.result == "success" {

                    let message = response.message ?? "Profile Updated"

                    print("✅ PROFILE UPDATED:", message)

                    registrationState = .success(message)

                } else {

                    let message = response.message ?? "Failed To Update"

                    print("❌ PROFILE UPDATE FAILED:", message)

                    registrationState = .failure(message)
                }

            } catch {

                print("❌ PROFILE UPDATE ERROR:", error)

                registrationState = .failure(error.localizedDescription)
            }
        }
    }
    
    func getDriverDetails() {

        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        Task {

            defer {
                isLoading = false
            }

            do {

                let response = try await APIClient.shared.getDriverDetails()

                if response.result == "success" {

                    driver = response.driverData

                    print("✅ DRIVER NAME:", driver?.driverName ?? "")

                } else {

                    errorMessage = response.message
                }

            } catch {

                errorMessage = error.localizedDescription
                print(error)
            }
        }
    }
}
