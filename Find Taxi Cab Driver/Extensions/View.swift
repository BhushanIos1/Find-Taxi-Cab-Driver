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
        pickup: String,
        drop: String,
        needs: String
    ) -> some View {
        
        self.overlay {
            if isPresented.wrappedValue {
                RideRequestPopup(
                    isPresented: isPresented,
                    pickupLocation: pickup,
                    dropLocation: drop,
                    specialNeeds: needs
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
        onSubmit: @escaping (String) -> Void
    ) -> some View {
        
        self.overlay {
            if isPresented.wrappedValue {
                CancelPopupView(
                    isPresented: isPresented,
                    title: title,
                    placeholder: placeholder,
                    buttonTitle: buttonTitle,
                    onSubmit: onSubmit
                )
                .zIndex(9999)
            }
        }
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

    var apiDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: self)
    }

    var apiTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss Z"
        return formatter.string(from: self)
    }
}
