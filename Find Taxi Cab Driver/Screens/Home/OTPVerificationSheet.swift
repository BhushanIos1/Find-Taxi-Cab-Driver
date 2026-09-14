//
//  OTPVerificationSheet.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 21/08/26.
//

import SwiftUI
import SwiftfulLoadingIndicators

/// The trip-start gate: the driver has arrived, the customer reads out their
/// 4-digit code, and the trip only begins once the server confirms it.
///
/// This sheet verifies and nothing more — `onVerified` hands control back so the
/// caller can post `onboard`. Keeping the two apart is what stops a wrong code
/// from starting a trip.
struct OTPVerificationSheet: View {

    @Environment(\.colorScheme)
    private var colorScheme

    @Environment(\.dismiss)
    private var dismiss

    @ObservedObject
    var bookingViewModel: BookingViewModel

    let bookingId: String

    /// Called once the server has accepted the code. The sheet is already
    /// dismissing by then.
    var onVerified: () -> Void

    @State private var otp = ""

    /// Shown under the boxes — an inline message the driver can read while the
    /// keypad is still up, rather than a toast that slides away behind the sheet.
    @State private var statusMessage: String?
    @State private var isStatusAnError = false


    private var canVerify: Bool {
        otp.count == 4 && !bookingViewModel.isOTPLoading
    }

    var body: some View {

        ZStack {

            VStack(spacing: 22) {

                header
                pinField

                if let statusMessage {

                    Text(statusMessage)
                        .font(AppFont.font(.regular, size: 14))
                        .foregroundStyle(isStatusAnError ? Color.red : AppColors.greenAppColor)
                        .multilineTextAlignment(.center)
                        .transition(.opacity)
                }

                resendButton

                Spacer(minLength: 0)

                actionButtons
            }
            .padding(25)

            if bookingViewModel.isOTPLoading {

                Color.black.opacity(0.15)
                    .ignoresSafeArea()

                LoadingIndicator(
                    animation: .circleTrim,
                    color: AppColors.primaryYellow,
                    size: .medium,
                    speed: .normal
                )
            }
        }
        .animation(.easeInOut(duration: 0.2), value: statusMessage)
        .onChange(of: bookingViewModel.otpState) { state in

            guard let state else { return }

            handle(state)

            bookingViewModel.otpState = nil
        }
    }
}

private extension OTPVerificationSheet {

    var header: some View {

        VStack(spacing: 10) {

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 40))
                .foregroundStyle(AppColors.primaryYellow)

            Text("Enter Trip OTP")
                .font(AppFont.font(.medium, size: 24))

            Text("Ask the customer for the 4-digit code sent to their phone. The trip starts once it's verified.")
                .font(AppFont.font(.regular, size: 14))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    var pinField: some View {
        OTPInputField(code: $otp)
    }

    var resendButton: some View {

        Button {
            statusMessage = nil
            bookingViewModel.sendRideOTP(bookingId: bookingId)
        } label: {
            Text("Didn't get it? Resend OTP")
                .font(AppFont.font(.medium, size: 14))
                .foregroundStyle(AppColors.appBlueColor)
        }
        .disabled(bookingViewModel.isOTPLoading)
    }

    var actionButtons: some View {

        HStack(spacing: 10) {

            Button {
                dismiss()
            } label: {
                Text("CANCEL")
                    .font(AppFont.font(.medium, size: 16))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(colorScheme == .dark
                                ? Color.gray.opacity(0.2)
                                : Color(.darkGray))
                    .foregroundStyle(.white)
                    .cornerRadius(7)
            }
            .disabled(bookingViewModel.isOTPLoading)

            Button {
                bookingViewModel.verifyRideOTP(bookingId: bookingId, otp: otp)
            } label: {

                Text(bookingViewModel.isOTPLoading ? "VERIFYING…" : "START TRIP")
                    .font(AppFont.font(.medium, size: 18))
                    .frame(maxWidth: .infinity)
                    .padding()
                    // Greyed out until four digits are in, so there is nothing to
                    // tap that could fail for a reason the driver can't see.
                    .background(canVerify ? AppColors.primaryYellow : AppColors.primaryYellow.opacity(0.4))
                    .foregroundStyle(.black)
                    .cornerRadius(7)
            }
            .disabled(!canVerify)
        }
    }

    func handle(_ state: RideOTPState) {

        switch state {

        case .sent(let message):
            isStatusAnError = false
            statusMessage = message

        case .sendFailed(let message):
            isStatusAnError = true
            statusMessage = message

        case .verified:
            // Hand back first, then close — the caller posts `onboard`.
            onVerified()
            dismiss()

        case .verifyFailed(let message):
            isStatusAnError = true
            statusMessage = message

            // Clear the boxes so the driver can simply retype, instead of having
            // to delete four digits first.
            otp = ""
        }
    }
}
