//
//  BankDetailsView.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 06/03/26.
//

import SwiftUI
import SwiftfulLoadingIndicators

struct BankDetailsView: View {
    
    @EnvironmentObject
    private var router: AppRouter
    
    @EnvironmentObject
    private var toastManager: ToastManager
    
    @State private var name = ""
    @State private var nameError: String?
    
    @State private var bankName = ""
    @State private var bankNameError: String?
    
    @State private var sortCode = ""
    @State private var sortCodeError: String?
    
    @State private var accountNumber = ""
    @State private var accountNumberError: String?
    
    @StateObject
    private var viewModel = PaymentViewModel()
    
    var body: some View {
        
        ZStack {
            
            VStack(spacing: 0) {
                
                ScrollView(showsIndicators: false) {
                    
                    VStack(spacing: 25) {
                        
                        AppTextField(
                            title: "Account Holder Name",
                            text: $name,
                            error: nameError,
                            foregroundColor: Color(uiColor: .label)
                        )
                        
                        AppTextField(
                            title: "Bank Name",
                            text: $bankName,
                            error: bankNameError,
                            foregroundColor: Color(uiColor: .label)
                        )
                        
                        AppTextField(
                            title: "Sort Code",
                            text: $sortCode,
                            error: sortCodeError,
                            keyboard: .numberPad,
                            foregroundColor: Color(uiColor: .label)
                        )
                        
                        AppTextField(
                            title: "Account Number",
                            text: $accountNumber,
                            error: accountNumberError,
                            keyboard: .numberPad,
                            foregroundColor: Color(uiColor: .label)
                        )
                        
                        bottomSection
                    }
                }
                .padding(.vertical, 30)
                .padding(.horizontal, 20)
            }
            
            // MARK: Loader
            
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
            title: "Bank Details",
            leading: .back
        ) {
            router.pop()
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
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    router.pop()
                }
                
            case .failure(let message):
                
                toastManager.showToast(
                    type: .error,
                    title: "Failed",
                    subtitle: message
                )
            }
            
            DispatchQueue.main.async {
                viewModel.paymentState = nil
            }
        }
        .overlay(
            GlobalToastView()
                .environmentObject(toastManager)
        )
    }
}

private extension BankDetailsView {
    
    var bottomSection: some View {
        
        Button {
            
            var isValid = true
            
            if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                nameError = "Account Holder Name is required"
            } else {
                nameError = nil
            }
            
            if bankName.isEmpty {
                bankNameError = "Bank Name is required"
                isValid = false
            } else {
                bankNameError = nil
            }
            
            if sortCode.isEmpty {
                sortCodeError = "Sort Code is required"
                isValid = false
            } else {
                sortCodeError = nil
            }
            
            if accountNumber.isEmpty {
                accountNumberError = "Account Number is required"
                isValid = false
            } else {
                accountNumberError = nil
            }
            
            guard isValid else { return }
            
            viewModel.updateBankDetails(
                accountHolderName: name,
                bankName: bankName,
                sortCode: sortCode,
                accountNumber: accountNumber
            )
            
        } label: {
            
            Text("UPDATE")
                .primaryButtonStyle()
        }
        .padding(.vertical, 20)
    }
}

#Preview {
    BankDetailsView()
}
