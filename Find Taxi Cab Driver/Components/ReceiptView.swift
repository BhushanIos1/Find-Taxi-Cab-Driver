//
//  ReceiptView.swift
//  Find Taxi Cab
//
//  Created by Bhushan Kumar on 19/03/26.
//

import SwiftUI

/// The end-of-trip TRIP FARE dialog — Android's `showFeedbackDialog()` in
/// `RouteDetailsActivity`.
///
/// The driver enters the final price plus any toll, rates the rider and leaves a
/// comment; it all goes up in one `/miles_cal` call. Until that lands, the
/// booking has no final price for the rider to pay, which is why CANCEL leaves
/// the trip open rather than ending it.
struct ReceiptView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    let pickupLocation: String
    let dropLocation: String
    
    /// Drives the SUBMIT label and blocks double taps while `/miles_cal` is away.
    var isSubmitting: Bool = false
    
    var onSubmit: (_ price: String, _ tollCharge: String, _ comment: String, _ rating: Int) -> Void = { _, _, _, _ in }
    var onCancel: () -> Void = { }
    
    @State private var isTollSelected = false
    @State private var rating: Int = 5
    @State private var fare: String = ""
    @State private var tollCharge: String = ""
    @State private var comment: String = ""
    
    @FocusState private var isFareFocused: Bool
    @FocusState private var isTollFocused: Bool
    @FocusState private var isCommentFocused: Bool
    
    /// `/miles_cal` needs a real number. Anything else — blank, "abc", a stray
    /// currency symbol — would post a fare the rider can never be charged.
    private var canSubmit: Bool {
        !isSubmitting && Double(fare.trimmingCharacters(in: .whitespaces)) != nil
    }
    
    var body: some View {
        
        VStack(alignment: .leading, spacing: 18) {
            
            Text("TRIP FARE")
                .font(AppFont.font(.medium, size: 20))
            
            Divider()
            
            InfoRowView(
                title: "Source",
                value: pickupLocation
            )
            
            InfoRowView(
                title: "Destination",
                value: dropLocation
            )
            
            VStack(spacing: 6) {
                
                TextField("Enter Fare (£)", text: $fare)
                    .keyboardType(.decimalPad)
                    .focused($isFareFocused)
                    .font(AppFont.font(.semiBold, size: 20))
                    .tint(AppColors.primaryYellow)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(isFareFocused ? AppColors.primaryYellow : .gray.opacity(0.5))
                    .animation(.easeInOut(duration: 0.2), value: isFareFocused)
            }
            .padding(.vertical, 15)
            
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isTollSelected.toggle()
                    }
                } label: {
                    Image(systemName: isTollSelected ? "checkmark.square.fill" : "square")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .foregroundColor(colorScheme == .dark
                                         ? Color.white
                                         : Color.black)
                }
                
                Text("Toll and Congestion Charges")
                    .font(AppFont.font(.regular, size: 20))
            }
            
            if isTollSelected {
                
                VStack(spacing: 6) {
                    
                    TextField("Extra Charges (from £2 upto)", text: $tollCharge)
                        .keyboardType(.decimalPad)
                        .focused($isTollFocused)
                        .font(AppFont.font(.regular, size: 16))
                        .tint(AppColors.primaryYellow)
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(isTollFocused ? AppColors.primaryYellow : .gray.opacity(0.5))
                        .animation(.easeInOut(duration: 0.2), value: isTollFocused)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // RATING
            VStack(alignment: .leading, spacing: 10) {
                
                Text("Rate Customer")
                    .font(AppFont.font(.semiBold, size: 20))
                
                HStack(spacing: 6) {
                    ForEach(1...5, id: \.self) { index in
                        Image(systemName: index <= rating ? "star.fill" : "star")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(AppColors.primaryYellow)
                            .onTapGesture {
                                rating = index
                            }
                    }
                }
            }
            .padding(.vertical, 15)
            
            // COMMENT
            VStack(spacing: 6) {
                
                TextField("Comment", text: $comment)
                    .focused($isCommentFocused)
                    .font(AppFont.font(.semiBold, size: 20))
                    .tint(AppColors.primaryYellow)
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(isCommentFocused ? AppColors.primaryYellow : .gray.opacity(0.5))
                    .animation(.easeInOut(duration: 0.2), value: isCommentFocused)
            }
            .padding(.bottom, 10)
            
            // BUTTONS
            HStack(spacing: 8) {
                
                Button {
                    submit()
                } label: {
                    Text(isSubmitting ? "SUBMITTING…" : "SUBMIT")
                        .font(AppFont.font(.medium, size: 18))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(canSubmit ? AppColors.greenAppColor : AppColors.greenAppColor.opacity(0.4))
                        .foregroundColor(.white)
                }
                .disabled(!canSubmit)
                
                Button {
                    onCancel()
                } label: {
                    Text("CANCEL")
                        .font(AppFont.font(.medium, size: 18))
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.red)
                        .foregroundColor(.white)
                }
                .disabled(isSubmitting)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(colorScheme == .dark
                      ? Color(.systemGray6)
                      : Color(.white))
                .shadow(radius: 5)
        )
        .padding(20)
    }
}

private extension ReceiptView {
    
    func submit() {
        
        let trimmedFare = fare.trimmingCharacters(in: .whitespaces)
        let trimmedToll = tollCharge.trimmingCharacters(in: .whitespaces)
        
        // An unticked box means no toll was charged, whatever is left in the
        // field from a moment of indecision. Empty rather than "0" because that
        // is what Android sends — `extraFare` stays "" unless its field is
        // visible — and the backend has only ever been exercised with that.
        let toll = (isTollSelected && !trimmedToll.isEmpty) ? trimmedToll : ""
        
        onSubmit(
            trimmedFare,
            toll,
            comment.trimmingCharacters(in: .whitespacesAndNewlines),
            rating
        )
    }
}

#Preview {
    ReceiptView(
        pickupLocation: "AD 361, Kali mandir, Sarat Pally Karunamoyee...",
        dropLocation: "Sealdah Station Sealdah, Raja Bazar, Calcutta..."
    )
}
