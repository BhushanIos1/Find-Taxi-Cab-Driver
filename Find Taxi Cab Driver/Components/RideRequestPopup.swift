//
//  RideRequestPopup.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 21/03/26.
//

import SwiftUI
import Combine
import SwiftfulLoadingIndicators

struct RideRequestPopup: View {
    
    @Environment(\.colorScheme) var colorScheme

    @Environment(\.scenePhase) private var scenePhase

    @EnvironmentObject
    private var toastManager: ToastManager
    
    @Binding var isPresented: Bool

    let bookingId: String
    let pickupLocation: String
    let dropLocation: String
    let specialNeeds: String

    /// Called after the server confirms the ACCEPT — lets the presenting screen
    /// (e.g. `HomeScreen`) pick up the now-active booking and draw the route.
    var onAccepted: (() -> Void)? = nil

    @StateObject private var timerManager = RideTimerManager()

    @StateObject
    private var bookingViewModel = BookingViewModel()

    /// Tracks which action is in flight so the shared `bookingState` success/failure
    /// handler below knows whether to fire `onAccepted`.
    @State private var pendingAction: BookingAction?

    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        
        ZStack {
            
            // Background
            Color.black.opacity(0.25)
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                
                // Header
                Text("Auto Reject In : \(timerManager.remainingTime)")
                    .foregroundColor(.red)
                    .font(AppFont.font(.medium, size: 20))
                
                Divider()
                
                InfoRowView(
                    title: "Pick Up\nLocation:",
                    value: pickupLocation
                )
                
                Divider()
                
                InfoRowView(
                    title: "Drop\nLocation:",
                    value: dropLocation
                )
                
                Divider()
                
                InfoRowView(
                    title: "Special Needs:",
                    value: specialNeeds
                )
                
                Divider()
                
                // Buttons
                HStack(spacing: 12) {
                    
                    Button {
                        acceptAction()
                    } label: {
                        Text("ACCEPT")
                            .font(AppFont.font(.medium, size: 18))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.greenAppColor)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    
                    Button {
                        rejectAction()
                    } label: {
                        Text("REJECT")
                            .font(AppFont.font(.medium, size: 18))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    .disabled(bookingViewModel.isLoading)
                }
            }
            .padding()
            .background(colorScheme == .dark
                        ? Color(.systemGray6)
                        : Color(.white))
            .cornerRadius(6)
            .padding(.horizontal, 20)
            
            // MARK: - Loading Overlay
            if bookingViewModel.isLoading {
                
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                
                LoadingIndicator(
                    animation: .circleTrim,
                    color: AppColors.primaryYellow,
                    size: .medium,
                    speed: .normal
                )
            }
        }
        .onAppear {
            timerManager.start(duration: 15)
        }
        .onDisappear {
            timerManager.stop()
        }
        .onChange(of: scenePhase) { phase in

            // An offer that arrives while the app is backgrounded would otherwise
            // burn its whole 15s countdown unseen and auto-reject before the driver
            // ever opens the app — looking exactly like "the popup never appeared".
            // Restart the clock whenever the app actually comes to the foreground,
            // so the driver always gets a full 15 visible seconds to decide.
            guard phase == .active, pendingAction == nil else { return }

            timerManager.start(duration: 15)
        }
        .onReceive(timerManager.$remainingTime) { value in
            if value == 0 && !bookingViewModel.isLoading {
                // Auto-reject on timeout — was previously a silent local dismiss
                // that never told the server, leaving the booking stuck pending.
                rejectAction()
            }
        }
        .onChange(of: bookingViewModel.bookingState) { state in

            guard let state else { return }

            switch state {

            case .success(let message):

                print("✅ BOOKING STATUS SUCCESS:", message)

                if pendingAction == .accept {
                    onAccepted?()
                }

                dismiss()

            case .failure(let message):
                print("❌ BOOKING STATUS FAILED:", message)
                toastManager.showToast(
                    type: .error,
                    title: "Failed",
                    subtitle: message
                )
            }
            
            bookingViewModel.bookingState = nil
        }
        .overlay(
            GlobalToastView()
                .environmentObject(toastManager)
        )
    }
}

// MARK: - Actions
private extension RideRequestPopup {
    
    func acceptAction() {

        guard !bookingViewModel.isLoading else {
            return
        }

        timerManager.stop()
        pendingAction = .accept

        bookingViewModel.changeBookingStatus(
            bookingId: bookingId,
            action: .accept
        )
    }

    func rejectAction() {

        guard !bookingViewModel.isLoading else {
            return
        }

        timerManager.stop()
        pendingAction = .reject

        bookingViewModel.changeBookingStatus(
            bookingId: bookingId,
            action: .reject
        )
    }
    
    func dismiss() {
        isPresented = false
    }
}

#Preview {
    RideRequestPopup(isPresented: .constant(false),
                     bookingId: "12345",
                     pickupLocation: "AD 361, Kali mandir, Sarat Pally Karunamoyee...",
                     dropLocation: "Sealdah Station Sealdah, Raja Bazar, Calcutta...",
                     specialNeeds: "Wheelchair")
}
