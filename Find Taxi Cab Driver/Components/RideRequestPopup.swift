//
//  RideRequestPopup.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 21/03/26.
//

import SwiftUI
import Combine

struct RideRequestPopup: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var isPresented: Bool
    
    let pickupLocation: String
    let dropLocation: String
    let specialNeeds: String
    
    @StateObject private var timerManager = RideTimerManager()
    
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
                }
            }
            .padding()
            .background(colorScheme == .dark
                        ? Color(.systemGray6)
                        : Color(.white))
            .cornerRadius(6)
            .padding(.horizontal, 20)
        }
        .onAppear {
            timerManager.start(duration: 15)
        }
        .onDisappear {
            timerManager.stop()
        }
        .onReceive(timerManager.$remainingTime) { value in
            if value == 0 {
                dismiss()
            }
        }
    }
}

// MARK: - Actions
private extension RideRequestPopup {
    
    func acceptAction() {
        timerManager.stop()
        dismiss()
        // API Call → Accept Ride
    }
    
    func rejectAction() {
        timerManager.stop()
        dismiss()
        // API Call → Reject Ride
    }
    
    func dismiss() {
        isPresented = false
    }
}

#Preview {
    RideRequestPopup(isPresented: .constant(false),
                     pickupLocation: "AD 361, Kali mandir, Sarat Pally Karunamoyee...",
                     dropLocation: "Sealdah Station Sealdah, Raja Bazar, Calcutta...",
                     specialNeeds: "Wheelchair")
}
