//
//  HelpSCreen.swift
//  Find Taxi Cab
//
//  Created by Bhushan Kumar on 01/03/26.
//

import SwiftUI

struct PaymentHistoryScreen: View {
    
    @EnvironmentObject
    private var router: AppRouter
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        
        ZStack {
            
            ScrollView(showsIndicators: false) {
                
                VStack {
                    
                    Text("Total Payment : £0.00")
                        .font(AppFont.font(.medium, size: 16))
                        .padding(.vertical, 16)
                    
                    Divider()
                        .background(
                            colorScheme == .dark ? Color.white : Color.gray
                        )
                    
                    Text("Total Jobs : 00")
                        .font(AppFont.font(.medium, size: 16))
                        .padding(.vertical, 16)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(uiColor: .systemBackground))
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 4)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(colorScheme == .dark
                                ? Color(.white)
                                : Color(.black), lineWidth: 0.8)
                )
                .padding(20)
            }
        }
        .appNavigationBar(
            title: "Payment History",
            leading: .back) {
                router.pop()
            }
    }
}

#Preview {
    PaymentHistoryScreen()
}
