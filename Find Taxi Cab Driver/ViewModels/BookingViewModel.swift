//
//  BookingViewModel.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 19/06/26.
//

enum BookingState: Equatable {
    case success(String)
    case failure(String)
}

import Foundation
import SwiftUI

@MainActor
final class BookingViewModel: ObservableObject {
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var bookingState: BookingState?
    
    @Published var lastBooking: BookingDetailsModel?
    @Published var bookings: [BookingDetailsModel] = []
    
    func getLastBooking() {
        
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            
            defer { isLoading = false }
            
            do {
                
                let response: DriverLastBookingResponse =
                try await APIClient.shared.request(
                    DriverAPI.lastBooking,
                    responseType: DriverLastBookingResponse.self
                )
                
                print("🚀 RESPONSE RESULT:", response.result)
                print("🚀 RESPONSE MESSAGE:", response.message ?? "nil")
                
                if response.result.trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased() == "success" {
                    print("✅ SUCCESS BLOCK")
                    
                    lastBooking = response.lastBook
                    bookingState = .success(response.message ?? "Last Booking Loaded")
                    
                } else {
                    
                    print("❌ FAILURE BLOCK")
                    
                    let message = response.message ?? "No Booking Found"
                    errorMessage = message
                    bookingState = .failure(message)
                }
                
            } catch {
                
                errorMessage = error.localizedDescription
                bookingState = .failure(error.localizedDescription)
                
                print("❌ LAST BOOKING ERROR")
                print(error)
            }
        }
    }
    
    func getBookingList() {
        
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            
            defer { isLoading = false }
            
            do {
                
                let response: DriverBookingListResponse =
                try await APIClient.shared.request(
                    DriverAPI.bookingList,
                    responseType: DriverBookingListResponse.self
                )
                
                print("📖 BOOKING LIST RESULT:", response.result)
                
                if response.result.lowercased() == "success" {
                    
                    bookings = response.bookingData ?? []
                    
                    print("✅ TOTAL BOOKINGS:", bookings.count)
                    
                } else {
                    
                    let message = response.message ?? "You Do Not Have Any Booking"
                    errorMessage = message
                    print("❌ BOOKING LIST FAILED:", message)
                }
                
            } catch {
                
                print("❌ BOOKING LIST ERROR:", error)
                
                errorMessage = error.localizedDescription
            }
        }
    }
}
