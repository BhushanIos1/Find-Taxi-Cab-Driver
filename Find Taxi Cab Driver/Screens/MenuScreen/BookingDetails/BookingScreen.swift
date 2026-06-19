//
//  BookingScreen.swift
//  Find Taxi Cab
//
//  Created by Bhushan Kumar on 01/03/26.
//

import SwiftUI
import SwiftfulLoadingIndicators

struct BookingScreen: View {
    
    @EnvironmentObject
    private var router: AppRouter
    
    @Environment(\.colorScheme) var colorScheme
    
    @StateObject
    private var viewModel = BookingViewModel()
    
    var body: some View {
        
        ZStack {
            
            ScrollView(showsIndicators: false) {
                
                VStack(alignment: .leading) {
                    
                    //                    if let booking = viewModel.lastBooking {
                    //                        BookingCell(item: booking)
                    //                            .padding(20)
                    //                        Button {
                    //                            router.pop()
                    //                        } label: {
                    //                            Text("CONTINUE")
                    //                                .primaryButtonStyle()
                    //                        }
                    //                        .padding(.horizontal, 20)
                    //                    } else if let error = viewModel.errorMessage {
                    //
                    //                        Text(error)
                    //.font(AppFont.font(.regular, size: 14))
                    //                            .frame(maxWidth: .infinity)
                    //                            .padding(.top, 50)
                    //
                    //                    }
                    
                    LazyVStack(spacing: 10) {
                        
                        ForEach(viewModel.bookings) { booking in
                            BookingCell(item: booking)
                        }
                        
                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(AppFont.font(.regular, size: 14))
                                .frame(maxWidth: .infinity)
                                .padding(.top, 50)
                        }
                    }
                }
            }
            
            if viewModel.isLoading {
                
                Color.black.opacity(0.2)
                    .ignoresSafeArea()
                
                LoadingIndicator(
                    animation: .circleTrim,
                    color: AppColors.primaryYellow,
                    size: .medium,
                    speed: .normal
                )
            }
        }
        .appNavigationBar(
            title: "Booking Page",
            leading: .back) {
                router.pop()
            }
            .onAppear {
                //                viewModel.getLastBooking()
                viewModel.getBookingList()
            }
    }
}

#Preview {
    BookingScreen()
}
