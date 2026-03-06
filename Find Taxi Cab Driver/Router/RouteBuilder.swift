//
//  RouteBuilder.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 28/02/26.
//

import SwiftUI

struct RouteBuilder {
    
    @ViewBuilder
    static func build(_ route: AppRoute) -> some View {
        
        switch route {
            
        case .home:
            HomeScreen()
            
        case .jobHistory:
            JobHistoryScreen()
            
        case .paymentHistory:
            PaymentHistoryScreen()
            
        case .bankDetails:
            BankDetailsView()
            
        case .profile:
            ProfileView()
            
        case .changePassword:
            ChangePassword()
            
        case .emergency:
            EmergencyScreen()
            
        case .booking:
            BookingScreen()
            
        case .login:
            LoginScreen()
            
        case .forgotPassword:
            ForgotPasswordView()
            
        case .registration:
            RegisterScreen()
        }
    }
}
