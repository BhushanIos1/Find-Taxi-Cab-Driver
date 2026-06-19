//
//  HelpSCreen.swift
//  Find Taxi Cab
//
//  Created by Bhushan Kumar on 01/03/26.
//

import SwiftUI
import SwiftfulLoadingIndicators

struct PaymentHistoryScreen: View {
    
    @EnvironmentObject
    private var router: AppRouter
    
    @Environment(\.colorScheme) var colorScheme
    
    @EnvironmentObject
    private var toastManager: ToastManager
    
    @StateObject
    private var viewModel = PaymentViewModel()
    
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
                        .stroke(
                            colorScheme == .dark
                            ? Color.white
                            : Color.black,
                            lineWidth: 0.8
                        )
                )
                .padding(20)
            }
                        
            if viewModel.isLoading {
                
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .allowsHitTesting(true)
                
                LoadingIndicator(
                    animation: .circleTrim,
                    color: AppColors.primaryYellow,
                    size: .medium,
                    speed: .normal
                )
            }
        }
        .appNavigationBar(
            title: "Payment History",
            leading: .back
        ) {
            router.pop()
        }
        .onAppear {
            viewModel.getPaymentHistory()
        }
        .onChange(of: viewModel.paymentState) { state in
            
            guard let state else { return }
            
            switch state {
                
            case .success(let message):
                
                toastManager.showToast(
                    type: .success,
                    title: "Success",
                    subtitle: message
                )
                
            case .failure(let message):
                
                toastManager.showToast(
                    type: .error,
                    title: "Failed",
                    subtitle: message
                )
            }
            
            viewModel.paymentState = nil
        }
        .overlay(
            GlobalToastView()
                .environmentObject(toastManager)
        )
    }
}

#Preview {
    PaymentHistoryScreen()
}
