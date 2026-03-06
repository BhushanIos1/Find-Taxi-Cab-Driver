//
//  BookingScreen.swift
//  Find Taxi Cab
//
//  Created by Bhushan Kumar on 01/03/26.
//

import SwiftUI

struct BookingScreen: View {
    
    @EnvironmentObject
    private var router: AppRouter
    
    @Environment(\.colorScheme) var colorScheme
    
    let bookings: [BookingDetailsModel] = [BookingDetailsModel(
        status: "Booking Page",
        bookingId: "932",
        customerMobile: "1234567890",
        pickup: "Hindmotor, Uttarpara, West Bengal, India",
        drop: "Rishra, Pandit Satghara, West Bengal, India",
        bookingDate: "2026-02-07   13:39:00",
        bookingStatus: "Abandon"
    )]
    
    var body: some View {
        
        ZStack {
            
            ScrollView(showsIndicators: false) {
                
                VStack(alignment: .leading) {
                    
                    BookingCell(item: bookings.first!)
                        .padding(20)
                    
                    Button {
                        router.pop()
                    } label: {
                        Text("CONTINUE")
                            .primaryButtonStyle()
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .appNavigationBar(
            title: "Booking Page",
            leading: .back) {
                router.pop()
            }
    }
}

#Preview {
    BookingScreen()
}
