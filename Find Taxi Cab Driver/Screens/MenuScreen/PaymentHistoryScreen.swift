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
            
            if viewModel.payments.isEmpty, !viewModel.isLoading {
                
                VStack(spacing: 0) {
                    
                    summaryCard
                    
                    NoDataView(
                        icon: "creditcard",
                        message: viewModel.errorMessage ?? "No payments have been made to you yet."
                    )
                }
                
            } else {
                
                ScrollView(showsIndicators: false) {
                    
                    LazyVStack(spacing: 14) {
                        
                        summaryCard
                        
                        ForEach(viewModel.payments) { payment in
                            paymentRow(payment)
                        }
                    }
                    .padding(.bottom, 20)
                }
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

private extension PaymentHistoryScreen {
    
    /// The two headline figures from Android's layout — now actually derived from
    /// the payments the API returns, rather than the hardcoded "£0.00" / "00"
    /// that both apps have been showing.
    var summaryCard: some View {
        
        VStack {
            
            Text(viewModel.totalPaidDisplay)
                .font(AppFont.font(.medium, size: 16))
                .padding(.vertical, 16)
            
            Divider()
                .background(
                    colorScheme == .dark ? Color.white : Color.gray
                )
            
            Text(viewModel.totalJobsDisplay)
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
    
    func paymentRow(_ payment: PaymentHistoryModel) -> some View {
        
        HStack(alignment: .top) {
            
            VStack(alignment: .leading, spacing: 4) {
                
                if let bookingId = payment.bookingId, !bookingId.isEmpty {
                    
                    Text("Job #\(bookingId)")
                        .font(AppFont.font(.medium, size: 15))
                }
                
                if let date = payment.paymentDate, !date.isEmpty {
                    
                    Text(date)
                        .font(AppFont.font(.regular, size: 13))
                        .foregroundStyle(.secondary)
                }
                
                if let method = payment.paymentMethod, !method.isEmpty {
                    
                    Text(method)
                        .font(AppFont.font(.regular, size: 13))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer(minLength: 8)
            
            Text(payment.amountDisplay)
                .font(AppFont.font(.semiBold, size: 16))
                .foregroundStyle(AppColors.greenAppColor)
        }
        .padding(14)
        .background(
            colorScheme == .dark
            ? Color(.systemGray6)
            : Color(.white)
        )
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(AppColors.yellowBorder, lineWidth: 0.8)
        )
        .padding(.horizontal, 20)
    }
}

#Preview {
    PaymentHistoryScreen()
}
