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
            LandingScreen()
            
        case .history:
            LandingScreen()
            
        case .booking:
            LandingScreen()
            
        case .emergency:
            LandingScreen()
            
        case .setting:
            LandingScreen()
            
        case .changePassword:
            LandingScreen()
            
        case .editCardDetails:
            LandingScreen()
            
        case .promotion:
            LandingScreen()
            
        case .about:
            LandingScreen()
            
        case .help:
            LandingScreen()
            
        case .login:
            LandingScreen()
            
        case .forgotPassword:
            LandingScreen()
            
        case .registration:
            LandingScreen()
        }
    }
}
