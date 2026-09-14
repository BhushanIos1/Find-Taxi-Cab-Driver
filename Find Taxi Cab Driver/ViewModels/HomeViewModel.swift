//
//  HomeViewModel.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 18/06/26.
//

import Foundation

enum HomeState: Equatable {
    case success(String)
    case failure(String)
}

@MainActor
final class HomeViewModel: ObservableObject {

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var homeState: HomeState?

    @Published var driverStatus: DriverStatus = .free

    /// Set once `checkBlockedStatus()` finds `driver_status == "blocked"`.
    /// Mirrors Android's `getDriverStatus()`, which stops the location-polling
    /// `Handler` and shows a block dialog when this happens.
    @Published var isBlocked = false

    init() {
        // A driver who had auto-accept switched on in an earlier build would stay
        // stuck on it forever otherwise, since nothing reads or clears the flag now.
        UserDefaults.standard.removeObject(forKey: "isAutoAcceptEnabled")

        driverStatus = DriverStatus(rawValue: AuthManager.shared.workStatus) ?? .free
    }
    
    // MARK: - Change Driver Status
    
    /// Confirms the driver's online/offline status with the server every time Home
    /// appears. This used to no-op whenever `AuthManager.shared.workStatus` was
    /// empty — which it is for any driver whose `driver_login` response never
    /// carried a `work_status` (a fresh account, for one) — so that driver showed
    /// "Free" locally (the in-memory default from `init()`) while the backend had
    /// no record of them being available at all, and never routed them a booking.
    /// Falling back to `.free` here instead of returning early is what actually
    /// makes the driver discoverable the first time they open the app.
    func syncStatusOnAppear() {

        let savedStatus = AuthManager.shared.workStatus.isEmpty
            ? DriverStatus.free.rawValue
            : AuthManager.shared.workStatus

        Task {

            do {

                let response: CommonResponse =
                try await APIClient.shared.request(
                    DriverAPI.changeStatus(status: savedStatus),
                    responseType: CommonResponse.self
                )

                if response.result == "success" {

                    driverStatus = DriverStatus(rawValue: savedStatus) ?? .free
                    AuthManager.shared.workStatus = savedStatus
                }

                print("✅ STATUS SYNC")
                print(response)

            } catch {
                print("❌ STATUS SYNC ERROR")
                print(error)
            }
        }
    }
    
    func changeStatus() {
        
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        let newStatus: DriverStatus = driverStatus == .free ? .busy : .free
        
        Task {
            
            defer {
                isLoading = false
            }
            
            do {
                
                let response: CommonResponse =
                try await APIClient.shared.request(
                    DriverAPI.changeStatus(
                        status: newStatus.rawValue
                    ),
                    responseType: CommonResponse.self
                )
                
                if response.result == "success" {
                    
                    driverStatus = newStatus
                    
                    AuthManager.shared.workStatus = newStatus.rawValue
                                        
                    homeState = .success(response.message ?? "Status Updated")
                    
                } else {
                    
                    let message = response.message ?? "Failed"
                    errorMessage = message
                    homeState = .failure(message)
                }
                
            } catch {
                
                errorMessage = error.localizedDescription
                homeState = .failure(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Update Driver Location

    func updateLocation(latitude: Double, longitude: Double, bookingId: String = "") {

        guard !isBlocked else { return }

        Task {

            do {

                let response: CommonResponse = try await APIClient.shared.request(
                    DriverAPI.updateLocation(lat: "\(latitude)", lng: "\(longitude)", bookingId: bookingId),
                    responseType: CommonResponse.self)

                print("📍 LOCATION UPDATED (booking: \(bookingId.isEmpty ? "none" : bookingId)):", response.result ?? "")

            } catch {

                print("❌ LOCATION UPDATE ERROR:", error)
            }
        }
    }

    // MARK: - Blocked Account Check

    /// One-shot check on screen appear — same trigger point as Android's
    /// `getDriverStatus()` call in `MainActivity.initView()`. The `block` push status
    /// (handled separately via `NotificationManager`) covers the real-time case; this
    /// covers a driver who was blocked while the app wasn't running to receive it.
    func checkBlockedStatus() {

        Task {

            do {

                let response: DriverStatusResponse = try await APIClient.shared.request(
                    DriverAPI.getDriverStatus,
                    responseType: DriverStatusResponse.self
                )

                if response.driverStatus?.lowercased() == "blocked" {
                    isBlocked = true
                }

            } catch {

                print("❌ DRIVER STATUS CHECK ERROR:", error)
            }
        }
    }
}

struct DriverStatusResponse: Decodable {
    let result: String?
    let driverStatus: String?

    enum CodingKeys: String, CodingKey {
        case result
        case driverStatus = "driver_status"
    }
}
