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
    
    
    /// A ride offer awaiting the driver's accept/reject — and nothing else.
    /// Setting this **opens the offer popup**, so it must only ever be written by
    /// the `booking` push flow. It was previously named `bookingDetails` and
    /// doubled as general trip data, which meant restoring an in-progress trip
    /// re-opened the accept/reject dialog for a job the driver was already on.
    @Published var incomingOffer: BookingData?

    /// Set by `restoreActiveBooking()` when the server reports a trip still in
    /// progress. Separate from `incomingOffer` precisely so a restore can never
    /// be mistaken for a fresh offer.
    @Published var restorableBooking: BookingData?

    /// The same `driver_last_book` record, fetched for display on the Booking
    /// Page rather than to auto-resume. Held separately from `restorableBooking`
    /// so opening that screen can never trigger the silent restore path.
    @Published var lastActiveBooking: BookingData?
    
    @Published var lastBookingAction: LstBookingAction?

    // MARK: - Ride OTP
    //
    // Kept off `bookingState` on purpose. Both HomeScreen and the OTP sheet
    // observe that one publisher, so routing OTP results through it meant each
    // had to guess, from `lastBookingAction`, whether a given event was theirs —
    // and they guessed wrong: a *failed* send opened the sheet, and a *failed*
    // verify closed it with a green "Success" toast.

    @Published var otpState: RideOTPState?
    @Published var isOTPLoading = false
    
    /// Asks the server whether this driver has a trip still in progress — the
    /// recovery path after the app is killed mid-trip. Deliberately hits the API
    /// rather than restoring from local storage: the booking may have been
    /// cancelled or reassigned server-side while the app was closed, so the
    /// server is the only trustworthy source for "am I still on this job".
    ///
    /// Doesn't touch `isLoading`/`bookingState` — this runs silently on launch
    /// alongside the other appear-time calls and must not spawn error toasts or
    /// block the offer flow if the driver simply has no active trip.
    func restoreActiveBooking() {

        Task {

            do {

                let response: DriverActiveBookingResponse = try await APIClient.shared.request(
                    DriverAPI.lastBooking,
                    responseType: DriverActiveBookingResponse.self
                )

                guard response.result.lowercased() == "success",
                      let booking = response.lastBook else {
                    print("ℹ️ No restorable trip for this driver.")
                    return
                }

                print("🔄 Restorable booking found — id \(booking.bookingId ?? "nil"), status \(booking.bookingStatus ?? "nil")")

                restorableBooking = booking

            } catch {
                print("❌ RESTORE ACTIVE BOOKING ERROR:", error)
            }
        }
    }

    /// `POST /driver_last_book` with `{driver_id}` — Android's
    /// `BookingPage.getBookingStatus()`.
    ///
    /// Same endpoint as `restoreActiveBooking()` but the user-facing version: it
    /// shows the spinner and reports failures, because the driver opened this
    /// screen deliberately and a blank page with no explanation tells them nothing.
    func loadLastBooking() {

        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        Task {

            defer { isLoading = false }

            do {

                let response: DriverActiveBookingResponse = try await APIClient.shared.request(
                    DriverAPI.lastBooking,
                    responseType: DriverActiveBookingResponse.self
                )

                if response.result.lowercased() == "success",
                   let booking = response.lastBook {

                    print("📋 LAST BOOKING: id \(booking.bookingId ?? "nil"), status \(booking.bookingStatus ?? "nil")")
                    lastActiveBooking = booking

                } else {

                    // Android shows the server's message in a Toasty here.
                    let message = response.message ?? "No booking found"
                    print("ℹ️ LAST BOOKING:", message)

                    lastActiveBooking = nil
                    errorMessage = message
                }

            } catch {

                print("❌ LAST BOOKING ERROR:", error)

                lastActiveBooking = nil
                errorMessage = error.localizedDescription
            }
        }
    }

    func getBookingData(bookingId: String) {

        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        Task {

            defer { isLoading = false }

            do {

                let response: BookingDetailsResponse =
                try await APIClient.shared.request(
                    DriverAPI.getBookingData(
                        bookingId: bookingId
                    ),
                    responseType: BookingDetailsResponse.self
                )

                if response.result.lowercased() == "success" {

                    incomingOffer = response.bookingData

                    bookingState = .success("")

                } else {

                    let message = response.error ?? "No Booking Found"

                    errorMessage = message
                    bookingState = .failure(message)
                }

            } catch {

                errorMessage = error.localizedDescription
                bookingState = .failure(error.localizedDescription)

                print("❌ GET BOOKING DATA ERROR")
                print(error)
            }
        }
    }

    /// `/booking` — the counterpart of `getBookingData` for a booking admin
    /// assigned directly rather than through the normal driver-matching flow.
    /// Takes no parameters; the server resolves the pending admin booking for
    /// the authenticated driver on its own, so there's no `bookingId` to pass
    /// even though the triggering push carries one.
    func getAdminBookingData() {

        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        Task {

            defer { isLoading = false }

            // An admin booking's push fires the instant admin taps assign,
            // which can land on this device a beat before the booking is
            // actually resolvable server-side — a couple of short retries
            // absorb that race rather than losing the offer to a toast the
            // driver has no way to act on.
            let maxAttempts = 3

            for attempt in 1...maxAttempts {

                do {

                    let response: BookingDetailsResponse =
                    try await APIClient.shared.request(
                        DriverAPI.fetchAdminBooking,
                        responseType: BookingDetailsResponse.self
                    )

                    if response.result.lowercased() == "success" {

                        incomingOffer = response.bookingData

                        bookingState = .success("")
                        return
                    }

                    let message = response.error ?? "No Booking Found"

                    if attempt < maxAttempts {
                        print("⚠️ GET ADMIN BOOKING: attempt \(attempt)/\(maxAttempts) failed (\(message)) — retrying…")
                        try? await Task.sleep(for: .seconds(1.5))
                        continue
                    }

                    errorMessage = message
                    bookingState = .failure(message)

                } catch {

                    if attempt < maxAttempts {
                        print("⚠️ GET ADMIN BOOKING: attempt \(attempt)/\(maxAttempts) network error (\(error)) — retrying…")
                        try? await Task.sleep(for: .seconds(1.5))
                        continue
                    }

                    errorMessage = error.localizedDescription
                    bookingState = .failure(error.localizedDescription)

                    print("❌ GET ADMIN BOOKING ERROR")
                    print(error)
                }
            }
        }
    }

    /// Retries fetching a booking until its pickup/drop-off coordinates are
    /// present and numeric, or gives up — `latfrom`/`longifrom`/`latto`/`longto`
    /// can lag a beat behind the rest of the booking row being queryable (seen
    /// on an admin-assigned booking, not ruled out for a driver-matched one
    /// either). Without this, a route simply never draws and nothing says why.
    ///
    /// Deliberately bypasses `incomingOffer`/`bookingState` — those drive the
    /// accept/reject popup, and this runs for a trip the driver has *already*
    /// accepted. Re-fetching through `getBookingData`/`getAdminBookingData`
    /// instead would re-open that popup for a job already underway.
    func fetchBookingWithCoordinates(
        bookingId: String,
        isAdmin: Bool,
        initial: BookingData
    ) async -> BookingData {

        guard !bookingId.isEmpty, !Self.hasCoordinates(initial) else { return initial }

        let maxAttempts = 4

        for attempt in 1...maxAttempts {

            print("⚠️ ROUTE: coordinates missing for booking \(bookingId) (attempt \(attempt)/\(maxAttempts)) — retrying…")

            try? await Task.sleep(for: .seconds(2))

            do {

                let response: BookingDetailsResponse = try await APIClient.shared.request(
                    isAdmin ? DriverAPI.fetchAdminBooking : DriverAPI.getBookingData(bookingId: bookingId),
                    responseType: BookingDetailsResponse.self
                )

                if response.result.lowercased() == "success",
                   let refreshed = response.bookingData,
                   Self.hasCoordinates(refreshed) {
                    return refreshed
                }

            } catch {
                print("⚠️ ROUTE: coordinate retry fetch failed —", error)
            }
        }

        print("❌ ROUTE: giving up on coordinates for booking \(bookingId) after \(maxAttempts) attempts — no route will draw for this leg.")
        return initial
    }

    private static func hasCoordinates(_ booking: BookingData) -> Bool {

        guard let latFrom = booking.latFrom, Double(latFrom) != nil,
              let longiFrom = booking.longiFrom, Double(longiFrom) != nil,
              let latTo = booking.latTo, Double(latTo) != nil,
              let longiTo = booking.longiTo, Double(longiTo) != nil else {
            return false
        }

        return true
    }

    func changeBookingStatus(
        bookingId: String,
        action: BookingAction,
        cancelMessage: String? = nil
    ) {

        guard !isLoading else {
            print("⛔️ Booking status request already in progress")
            return
        }

        isLoading = true
        errorMessage = nil

        Task {

            defer {
                isLoading = false
            }

            do {

                print("""
                🚀 CHANGE BOOKING STATUS

                Booking ID:
                \(bookingId)

                Driver ID:
                \(AuthManager.shared.driverId)

                Status:
                \(action.rawValue)

                Cancel Message:
                \(cancelMessage ?? "")
                """)

                let response: CommonResponse =
                    try await APIClient.shared.request(
                        DriverAPI.changeBookingStatus(
                            bookingId: bookingId,
                            status: action.rawValue,
                            cancelMessage: cancelMessage
                        ),
                        responseType: CommonResponse.self
                    )

                print("""
                📥 CHANGE BOOKING STATUS RESPONSE

                Result:
                \(response.result ?? "nil")

                Message:
                \(response.message ?? "nil")
                """)

                if response.result?.lowercased() == "success" {

                    let message =
                        response.message ?? "Booking Status Updated"

                    print("✅ BOOKING STATUS UPDATED:", message)

                    bookingState = .success(message)

                } else {

                    let message =
                        response.message
                        ?? "Booking Can Not Be Proceeded, Something Went Wrong"

                    print("❌ BOOKING STATUS FAILED:", message)

                    errorMessage = message
                    bookingState = .failure(message)
                }

            } catch {

                print("❌ CHANGE BOOKING STATUS ERROR")
                print(error)

                errorMessage = error.localizedDescription
                bookingState = .failure(error.localizedDescription)
            }
        }
    }
    
    // MARK: - Final Fare

    /// Closes out the trip financially — `POST /miles_cal`, mirroring Android's
    /// `RouteDetailsActivity.giveFeedback()` which runs straight after COMPLETED.
    /// Skipping this leaves the booking with no final price, so the rider's
    /// `get_fair` and `do_payment` have nothing to work with.
    func submitFinalFare(
        bookingId: String,
        price: String,
        tollCharge: String,
        feedback: String,
        customerRate: String
    ) {

        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        lastBookingAction = .submitFare

        Task {

            defer { isLoading = false }

            do {

                let response: CommonResponse = try await APIClient.shared.request(
                    DriverAPI.submitFinalFare(
                        bookingId: bookingId,
                        price: price,
                        tollCharge: tollCharge,
                        feedback: feedback,
                        customerRate: customerRate
                    ),
                    responseType: CommonResponse.self
                )

                if response.result?.lowercased() == "success" {

                    print("✅ FINAL FARE SUBMITTED for booking \(bookingId)")
                    bookingState = .success(response.message ?? "Fare Submitted")

                } else {

                        let message = response.message ?? "Could Not Submit Fare"
                    print("❌ FINAL FARE FAILED — result: \(response.result ?? "nil"), reason: \(message)")
                    errorMessage = message
                    bookingState = .failure(message)
                }

            } catch {

                print("❌ FINAL FARE ERROR:", error)
                errorMessage = error.localizedDescription
                bookingState = .failure(error.localizedDescription)
            }
        }
    }

    // MARK: - Send Ride OTP

    /// `POST /send_ride_otp` with `{driver_id, booking_id}` — issues the trip code
    /// and delivers it to the customer by SMS. The rider app has no screen that
    /// shows it, so this is the only way the customer learns the code.
    func sendRideOTP(bookingId: String) {

        guard !isOTPLoading else { return }

        isOTPLoading = true

        Task {

            defer { isOTPLoading = false }

            do {

                print("🚀 SEND RIDE OTP — booking \(bookingId)")

                let response: CommonResponse = try await APIClient.shared.request(
                    DriverAPI.sendRideOTP(bookingId: bookingId),
                    responseType: CommonResponse.self
                )

                if response.result?.lowercased() == "success" {

                    let message = response.message ?? "OTP sent to the customer."
                    print("✅ SEND OTP SUCCESS:", message)
                    otpState = .sent(message)

                } else {

                    let message = response.message ?? "Could not send the OTP."
                    print("❌ SEND OTP FAILED:", message)
                    otpState = .sendFailed(message)
                }

            } catch {

                print("❌ SEND OTP ERROR:", error)
                otpState = .sendFailed(error.localizedDescription)
            }
        }
    }

    // MARK: - Verify Ride OTP

    /// `POST /verify_ride_otp` with `{driver_id, booking_id, otp}`.
    ///
    /// The trip does not start here — this only reports whether the code was
    /// right. Posting `onboard` is the caller's job, and only on `.verified`.
    func verifyRideOTP(bookingId: String, otp: String) {

        guard !isOTPLoading else { return }

        isOTPLoading = true

        Task {

            defer { isOTPLoading = false }

            do {

                print("🚀 VERIFY RIDE OTP — booking \(bookingId)")

                let response: CommonResponse = try await APIClient.shared.request(
                    DriverAPI.verifyRideOTP(bookingId: bookingId, otp: otp),
                    responseType: CommonResponse.self
                )

                if response.result?.lowercased() == "success" {

                    let message = response.message ?? "OTP verified."
                    print("✅ VERIFY OTP SUCCESS:", message)
                    otpState = .verified(message)

                } else {

                    let message = response.message ?? "Invalid OTP. Please check with the customer."
                    print("❌ VERIFY OTP FAILED:", message)
                    otpState = .verifyFailed(message)
                }

            } catch {

                print("❌ VERIFY OTP ERROR:", error)
                otpState = .verifyFailed(error.localizedDescription)
            }
        }
    }
}

/// What the OTP sheet is reacting to. Send and verify outcomes are distinct
/// cases so a delivery problem can never read as a wrong code, or vice versa.
enum RideOTPState: Equatable {
    case sent(String)
    case sendFailed(String)
    case verified(String)
    case verifyFailed(String)
}

enum LstBookingAction {
    case submitFare
}

enum BookingAction: String {
    case accept = "accept"
    case reject = "reject"
    case pickCustomer = "pickcustomer"
    case onboard = "onboard"
    case complete = "complete"
    case cancel = "cancel"
}
