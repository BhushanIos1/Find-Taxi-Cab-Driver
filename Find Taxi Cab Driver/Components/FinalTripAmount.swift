//
//  FinalTripAmount.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 21/03/26.
//

import SwiftUI

struct FinalTripAmount: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var isPresented: Bool
    
    let bookingAmt: String
    let paymentMethod: String
    let onSubmit: (String) -> Void
    
    var body: some View {
        
        ZStack {
            
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            VStack(alignment: .leading, spacing: 40) {
                
                VStack(spacing: 24) {
                    
                    HStack {
                        Text("Fare for this booking")
                        Spacer()
                        Text(bookingAmt)
                    }
                    
                    HStack {
                        Text("Payment Method:")
                        Spacer()
                        Text(paymentMethod)
                    }
                }
                .font(AppFont.font(.semiBold, size: 20))
                
                Button {
                    submitAction()
                } label: {
                    Text("OK")
                        .font(AppFont.font(.medium, size: 18))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.greenAppColor)
                        .foregroundColor(.white)
                        .cornerRadius(7)
                }
            }
            .padding(20)
            .background(colorScheme == .dark
                        ? Color(.systemGray6)
                        : Color(.white))
            .cornerRadius(6)
            .padding(.horizontal, 20)
        }
        .transition(.opacity.combined(with: .scale))
    }
}

// MARK: - Actions
private extension FinalTripAmount {
    
    func submitAction() {
        dismiss()
    }
    
    func dismiss() {
        isPresented = false
    }
}

#Preview {
    FinalTripAmount(isPresented: .constant(false),
                    bookingAmt: "£ 8.00",
                    paymentMethod: "Online"
    ) { text in
        print("User Input:", text)
    }
}
