//
//  View.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 26/02/26.
//

import SwiftUI

extension View {
    
    func appNavigationBar(
        title: String,
        leading: NavBarLeadingType,
        toggleBinding: Binding<Bool>? = nil,
        onMenuTap: (() -> Void)? = nil
    ) -> some View {

        modifier(
            AppNavigationBar(
                title: title,
                leading: leading,
                toggleBinding: toggleBinding,
                onMenuTap: onMenuTap
            )
        )
    }
    
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
    
    func primaryButtonStyle(
        height: CGFloat = 52,
        background: Color = AppColors.primaryYellow,
        textColor: Color = .white
    ) -> some View {
        
        modifier(
            PrimaryButtonModifier(
                height: height,
                background: background,
                textColor: textColor
            )
        )
    }
    
    func rideRequestPopup(
        isPresented: Binding<Bool>,
        bookingId: String,
        pickup: String,
        drop: String,
        needs: String,
        isAdminBooking: Bool = false,
        onAccepted: (() -> Void)? = nil
    ) -> some View {

        self.overlay {
            if isPresented.wrappedValue {
                RideRequestPopup(
                    isPresented: isPresented,
                    bookingId: bookingId,
                    pickupLocation: pickup,
                    dropLocation: drop,
                    specialNeeds: needs,
                    isAdminBooking: isAdminBooking,
                    onAccepted: onAccepted
                )
                .transition(.opacity.combined(with: .scale))
                .zIndex(999)
            }
        }
    }
    
    func inputPopup(
        isPresented: Binding<Bool>,
        title: String,
        placeholder: String,
        buttonTitle: String,
        isSubmitting: Bool = false,
        errorMessage: String? = nil,
        onSubmit: @escaping (String) -> Void
    ) -> some View {

        self.overlay {
            if isPresented.wrappedValue {
                CancelPopupView(
                    isPresented: isPresented,
                    title: title,
                    placeholder: placeholder,
                    buttonTitle: buttonTitle,
                    onSubmit: onSubmit,
                    isSubmitting: isSubmitting,
                    errorMessage: errorMessage
                )
                .zIndex(9999)
            }
        }
    }
    
    /// The end-of-trip TRIP FARE dialog, centred over the map behind a dimmed
    /// backdrop — the same shape as Android's `showFeedbackDialog()`.
    ///
    /// Deliberately not dismissable by tapping outside: `/miles_cal` has not run
    /// yet, so a stray tap would leave the trip with no final price and the rider
    /// with nothing to pay.
    func tripFarePopup(
        isPresented: Binding<Bool>,
        pickupLocation: String,
        dropLocation: String,
        isSubmitting: Bool,
        onSubmit: @escaping (_ price: String, _ tollCharge: String, _ comment: String, _ rating: Int) -> Void,
        onCancel: @escaping () -> Void
    ) -> some View {
        
        self.overlay {
            
            if isPresented.wrappedValue {
                
                ZStack {
                    
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                    
                    GeometryReader { proxy in
                        
                        ScrollView(showsIndicators: false) {
                            
                            VStack(spacing: 0) {
                                
                                Spacer(minLength: 0)
                                
                                ReceiptView(
                                    pickupLocation: pickupLocation,
                                    dropLocation: dropLocation,
                                    isSubmitting: isSubmitting,
                                    onSubmit: onSubmit,
                                    onCancel: onCancel
                                )
                                
                                Spacer(minLength: 0)
                            }
                            // Centres the card while it fits, and lets it scroll
                            // once the keyboard takes half the screen — rather
                            // than pushing SUBMIT off the bottom.
                            .frame(minHeight: proxy.size.height)
                        }
                        .scrollDismissesKeyboard(.interactively)
                    }
                }
                .transition(.opacity)
                .zIndex(9999)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isPresented.wrappedValue)
    }
    
    func showToast(isPresented: Binding<Bool>, type: ToastType, title: String, subtitle: String? = nil, onUndo: (() -> Void)? = nil) -> some View {
        self.overlay(
            ZStack {
                if isPresented.wrappedValue {
                    ToastView(toastType: type, title: title, subtitle: subtitle, onUndo: onUndo)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1)
                }
            }
        )
    }
}

extension Bundle {
    
    var appName: String {
        object(
            forInfoDictionaryKey: "CFBundleDisplayName"
        ) as? String
        ??
        object(
            forInfoDictionaryKey: "CFBundleName"
        ) as? String
        ??
        ""
    }
}

extension UIImage {

    func toBase64(compression: CGFloat = 0.7) -> String? {
        jpegData(compressionQuality: compression)?
            .base64EncodedString()
    }
}

extension Date {

    /// Fixed-format output for the API, never for display.
    ///
    /// The locale is pinned to `en_US_POSIX` deliberately. Without it a
    /// `DateFormatter` follows the device: on a phone with 24-Hour Time switched
    /// off, `HH` still renders as "2:32 PM", and under a non-Gregorian calendar
    /// `yyyy` is not the Gregorian year at all. Either one produces a timestamp
    /// the backend cannot store.
    private static let apiFormatter: DateFormatter = {

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        return formatter
    }()

    private func apiString(format: String) -> String {

        let formatter = Self.apiFormatter
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    var apiDate: String {
        apiString(format: "yyyy-MM-dd")
    }

    /// `HH:mm:ss` — a plain SQL TIME. This used to carry a ` Z` offset suffix,
    /// producing "14:32:07 +0530", which is not a time the column accepts.
    /// Android sends `hh:mm:ss` from `MainActivity.showDriverLocation()`.
    var apiTime: String {
        apiString(format: "HH:mm:ss")
    }
}
