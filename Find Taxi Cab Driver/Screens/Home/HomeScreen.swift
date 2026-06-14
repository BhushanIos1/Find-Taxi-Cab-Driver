//
//  HomeScreen.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 04/03/26.
//

import SwiftUI

struct HomeScreen: View {
    
    @EnvironmentObject
    private var router: AppRouter
    
    @State private var presentSideMenu = false
    
    @StateObject
    private var locationService = LocationService()
    
    @State private var showShareSheet = false
    @State private var showLogoutAlert = false
    
    @State private var isOnline = true
    
    @State private var status: DriverStatus
    
    @State private var showRidePopup = false
    
    @StateObject
    private var viewModel = RegisterViewModel()
    
    init(status: DriverStatus) {
        _status = State(initialValue: status)
    }
    
    var body: some View {
        
        ZStack {
            
            GoogleMapView()
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                bottomSection
            }
        }
        .appNavigationBar(
            title: "Home",
            leading: .menu, toggleBinding: $isOnline
        ) {
            withAnimation(.easeInOut) {
                presentSideMenu.toggle()
            }
        }
        .onAppear {
            locationService.requestLocation()
        }
        .alert("Logout",
               isPresented: $showLogoutAlert) {
            
            Button("NO", role: .cancel) { }
            
            Button("YES", role: .destructive) {
                viewModel.logOut(id: "\(AuthManager.shared.driverId)", router: router)
                
                router.push(.landingPage)
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [
                "Check out this amazing Taxi App 🚖",
                ""
            ])
        }
        .overlay(alignment: .leading) {
            
            SideMenu(
                isShowing: $presentSideMenu,
                content: AnyView(
                    SideMenuView(
                        presentSideMenu: $presentSideMenu
                    ) { selectedRow in
                        handleMenuNavigation(selectedRow)
                    }
                )
            )
        }
        .rideRequestPopup(
            isPresented: $showRidePopup,
            pickup: "AD 361, Kali mandir, Sarat Pally Karunamoyee...",
            drop: "Sealdah Station Sealdah, Raja Bazar, Calcutta...",
            needs: "None"
        )
        .inputPopup(
                isPresented: $showRidePopup,
                title: "Reason For Cancellation :",
                placeholder: "Type here...",
                buttonTitle: "SUBMIT"
            ) { text in
                print("User Input:", text)
            }
    }
}

private extension HomeScreen {
    
    var bottomSection: some View {
        
        DriverStatusToggle(status: $status)
            .frame(width: 260)
        
        /*VStack(spacing: 8) {
            HStack(spacing: 8) {
                
                ActionButtonView(
                    title: "ON BOARD",
                    backgroundColor: AppColors.greenAppColor
                ) {
                }
                
                ActionButtonView(
                    title: "CANCEL",
                    backgroundColor: .red
                ) {
                }
            }
            
            HStack(spacing: 8) {
                
                ActionButtonView(
                    title: "SEND SMS",
                    backgroundColor: AppColors.primaryYellow
                ) {
                }
                
                ActionButtonView(
                    title: "MAKE CALL",
                    backgroundColor: AppColors.appBlueColor
                ) {
                }
            }
        }
        .padding(.horizontal, 20)*/
    }
}

private extension HomeScreen {
    
    func handleMenuNavigation(_ menu: SideMenuRowType) {
        
        switch menu {
            
        case .jobHistory:
            router.push(.jobHistory)
            
        case .paymentHistory:
            router.push(.paymentHistory)
            
        case .bankDetails:
            router.push(.bankDetails)
            
        case .profile:
            router.push(.profile)
            
        case .changePassword:
            router.push(.changePassword)
            
        case .emergency:
            router.push(.emergency)
            
        case .bookingPage:
            router.push(.booking)
            
        case .logout:
            showLogoutAlert = true
        }
    }
}

#Preview {
    HomeScreen(status: .free)
}
