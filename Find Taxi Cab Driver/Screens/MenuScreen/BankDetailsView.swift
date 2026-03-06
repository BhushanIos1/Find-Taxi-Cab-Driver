//
//  BankDetailsView.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 06/03/26.
//

import SwiftUI

struct BankDetailsView: View {
    
    @EnvironmentObject
    private var router: AppRouter
    
    @State private var name = ""
    @State private var nameError: String?
    
    @State private var bankName = ""
    @State private var bankNameError: String?
    
    @State private var sortCode = ""
    @State private var sortCodeError: String?
    
    @State private var accountNumber = ""
    @State private var accountNumberError: String?
    
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            ScrollView(showsIndicators: false) {
                
                VStack(spacing: 25) {
                    AppTextField(title: "Account Holder Name", text: $name, error: nameError)
                    AppTextField(title: "Bank Name", text: $bankName, error: bankNameError)
                    AppTextField(title: "Sort Code", text: $sortCode, error: sortCodeError)
                    AppTextField(title: "Account Number", text: $accountNumber, error: accountNumberError)
                    
                    bottomSection
                }
            }
            .padding(.vertical, 30)
            .padding(.horizontal, 20)
        }
        .appNavigationBar(
            title: "Bank Details",
            leading: .back) {
                router.pop()
            }
    }
}

private extension BankDetailsView {
    
    var bottomSection: some View {
        
        Button {
            
            //            if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            //                nameError = "Name is required"
            //            } else {
            //                nameError = nil
            //            }
            //
            //            if email.isEmpty {
            //                emailError = "Email is required"
            //            }
            //            else if !ValidationHelper.isValidEmail(email) {
            //                emailError = "Enter valid email address"
            //            }
            //            else {
            //                emailError = nil
            //                print("✅ Email Valid")
            //            }
            router.push(.home)
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
