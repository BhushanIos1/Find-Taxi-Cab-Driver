//
//  BookingScreen.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 01/03/26.
//

import SwiftUI
import SwiftfulLoadingIndicators

/// Side menu ▸ Booking Page — Android's `BookingPage`.
///
/// One call, `driver_last_book` with `{driver_id}`, shown as a detail card.
/// CONTINUE returns to the job in progress, but only for the three states
/// Android allows; anything else is a finished or dead booking and says so.
///
/// This screen previously listed `driver_book_list` — the job *history* feed,
/// which is what the Job History menu item is for — so the two menu entries
/// showed the same thing and neither showed the last booking.
struct BookingScreen: View {
    
    @EnvironmentObject
    private var router: AppRouter
    
    @EnvironmentObject
    private var toastManager: ToastManager
    
    @Environment(\.colorScheme) var colorScheme
    
    @StateObject
    private var viewModel = BookingViewModel()
    
    var body: some View {
        
        ZStack {
            
            if let booking = viewModel.lastActiveBooking {
                bookingDetails(booking)
            } else if !viewModel.isLoading {
                emptyState
            }
            
            if viewModel.isLoading {
                
                Color.black.opacity(0.05)
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
                viewModel.loadLastBooking()
            }
            .overlay(
                GlobalToastView()
                    .environmentObject(toastManager)
            )
    }
}

private extension BookingScreen {
    
    func bookingDetails(_ booking: BookingData) -> some View {
        
        ScrollView(showsIndicators: false) {
            
            VStack(alignment: .leading, spacing: 18) {
                
                Text("Booking Details")
                    .font(AppFont.font(.medium, size: 18))
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                
                VStack(alignment: .leading, spacing: 14) {
                    
                    // The same six rows Android renders, in the same order.
                    detailRow("Booking Id :", booking.bookingId)
                    detailRow("Customer Mobile :", booking.customerPhone)
                    detailRow("Source Address :", booking.pickupAddress, isMultiline: true)
                    detailRow("Destination Address :", booking.dropAddress, isMultiline: true)
                    detailRow("Booking Date :", booking.addedOn)
                    detailRow("Booking State :", booking.bookingStatus?.capitalized)
                }
                .font(AppFont.font(.regular, size: 14))
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    colorScheme == .dark
                    ? Color(.systemGray6)
                    : Color(.white)
                )
                .shadow(
                    color: .black.opacity(0.08),
                    radius: 10,
                    x: 0,
                    y: 4
                )
                .padding(.horizontal, 20)
                
                Button {
                    continueBooking(booking)
                } label: {
                    Text("CONTINUE")
                        .primaryButtonStyle()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
    
    @ViewBuilder
    func detailRow(
        _ title: String,
        _ value: String?,
        isMultiline: Bool = false
    ) -> some View {
        
        HStack(alignment: isMultiline ? .top : .center) {
            
            Text(title)
            
            Text(value?.isEmpty == false ? value! : "-")
        }
    }
    
    var emptyState: some View {
        
        NoDataView(
            icon: "car",
            message: viewModel.errorMessage ?? "You have no recent bookings."
        )
    }
    
    /// `BookingPage.continue_booking()` — only `accept`, `pickcustomer` and
    /// `onboard` can be resumed; everything else is over and done with.
    ///
    /// Android pushes `RouteDetailsActivity` with the trip in an intent. Here the
    /// trip map lives on Home, which re-runs `restoreActiveBooking()` every time
    /// it appears — so returning to it is the whole handover, and it uses the
    /// server's current status rather than the one this screen happened to load.
    func continueBooking(_ booking: BookingData) {
        
        let resumable = ["accept", "pickcustomer", "onboard"]
        
        guard resumable.contains(booking.bookingStatus?.lowercased() ?? "") else {
            
            toastManager.showToast(
                type: .error,
                title: "Failed",
                subtitle: "You can't continue any booking!!!"
            )
            
            return
        }
        
        router.popToRoot()
    }
}

#Preview {
    BookingScreen()
}
