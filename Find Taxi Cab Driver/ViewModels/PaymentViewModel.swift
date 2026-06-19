//
//  PaymentViewModel.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 19/06/26.
//

enum PaymentState: Equatable {
    case success(String)
    case failure(String)
}

import SwiftUI
import Alamofire

@MainActor
final class PaymentViewModel: ObservableObject {
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var paymentState: PaymentState?
    
    @Published var payments: [PaymentHistoryModel] = []
    
    // MARK: - Update Bank Details
    
    func updateBankDetails(accountHolderName: String,
                           bankName: String,
                           sortCode: String,
                           accountNumber: String) {
        
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        let parameters: Parameters = [
            "account_holder_name": accountHolderName,
            "bank_name": bankName,
            "sort_code": sortCode,
            "bank_account_number": accountNumber
        ]
        
        Task {
            
            defer { isLoading = false }
            
            do {
                
                let response: CommonResponse = try await APIClient.shared.request(
                    DriverAPI.updateBankDetails(
                        parameters: parameters),
                    responseType: CommonResponse.self)
                
                if response.result?.lowercased() == "success" {
                    
                    let message = response.message ?? "Bank Details Updated"
                    paymentState = .success(message)
                    
                } else {
                    
                    let message = response.message ?? "Failed To Update Bank Details"
                    errorMessage = message
                    paymentState = .failure(message)
                }
                
            } catch {
                
                errorMessage = error.localizedDescription
                paymentState = .failure(error.localizedDescription)
                
                print("❌ UPDATE BANK ERROR")
                print(error)
            }
        }
    }
    
    // MARK: - Payment History
    
    func getPaymentHistory() {
        
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            
            defer { isLoading = false }
            
            do {
                
                let response: PaymentHistoryResponse = try await APIClient.shared.request(
                    DriverAPI.paymentHistory,
                    responseType: PaymentHistoryResponse.self)
                
                print("💰 PAYMENT HISTORY RESULT:", response.result)
                
                if response.result.lowercased() == "success" {
                    
                    payments = response.received ?? []
                    
                    paymentState = .success(response.message ?? "Payment History Loaded")
                    
                    print("✅ TOTAL PAYMENTS:", payments.count)
                    
                } else {
                    
                    let message = response.message ?? "No Payments Done"
                    
                    errorMessage = message
                    paymentState = .failure(message)
                    
                    print("❌ PAYMENT HISTORY FAILED:", message)
                }
                
            } catch {
                
                print("❌ PAYMENT HISTORY ERROR")
                print(error)
                
                errorMessage = error.localizedDescription
                paymentState = .failure(error.localizedDescription)
            }
        }
    }
}

struct PaymentHistoryResponse: Decodable {
    
    let result: String
    let message: String?
    let received: [PaymentHistoryModel]?
}

struct PaymentHistoryModel: Identifiable, Decodable {
    
    let id = UUID()
    
    let amount: String?
    let paymentDate: String?
    let paymentMethod: String?
    
    enum CodingKeys: String, CodingKey {
        case amount
        case paymentDate = "payment_date"
        case paymentMethod = "payment_method"
    }
}
