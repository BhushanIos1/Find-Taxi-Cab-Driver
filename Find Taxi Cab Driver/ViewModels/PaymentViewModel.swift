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
    
    /// Android's two headline figures — declared in its layout, never populated.
    /// Derived here rather than expected from the response, since nothing in
    /// either app establishes that the server sends them.
    var totalPaid: Double {
        payments.reduce(0) { $0 + $1.amountValue }
    }
    
    var totalPaidDisplay: String {
        String(format: "Total Payment : £%.2f", totalPaid)
    }
    
    var totalJobsDisplay: String {
        String(format: "Total Jobs : %02d", payments.count)
    }
    
    // MARK: - Update Bank Details
    
    func updateBankDetails(
        accountHolderName: String,
        bankName: String,
        sortCode: String,
        accountNumber: String
    ) {

        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        Task {

            defer { isLoading = false }

            do {

                let response = try await APIClient.shared.updateBankDetails(
                    accountHolderName: accountHolderName,
                    bankName: bankName,
                    sortCode: sortCode,
                    accountNumber: accountNumber
                )

                if response.result?.lowercased() == "success" {

                    let message = response.message ?? "Bank Details Updated"

                    print("✅ BANK DETAILS UPDATED")
                    print(message)

                    paymentState = .success(message)

                } else {

                    let message = response.message ?? "Failed To Update Bank Details"

                    print("❌ BANK UPDATE FAILED")
                    print(message)

                    errorMessage = message
                    paymentState = .failure(message)
                }

            } catch {

                print("❌ UPDATE BANK ERROR")
                print(error)

                errorMessage = error.localizedDescription
                paymentState = .failure(error.localizedDescription)
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
                
                print("💰 PAYMENT HISTORY RESULT:", response.result ?? "nil")
                
                if response.result?.lowercased() == "success" {
                    
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

/// `POST /payment_history_driver` with `{driver_id}`.
///
/// Android calls this and throws the response away — `PaymentHistoryActivity`'s
/// success branch is empty and its two totals come from the layout XML — so
/// there is no reference implementation to copy the key names from. The rows are
/// read under several plausible spellings for that reason; whichever the backend
/// actually uses will land.
struct PaymentHistoryResponse: Decodable {
    
    let result: String?
    let message: String?
    let received: [PaymentHistoryModel]?
    
    private struct AnyKey: CodingKey {
        
        let stringValue: String
        var intValue: Int? { nil }
        
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: AnyKey.self)
        
        func value(_ name: String) -> AnyKey? { AnyKey(stringValue: name) }
        
        result = value("result").flatMap { try? container.decodeIfPresent(String.self, forKey: $0) } ?? nil
        
        // Success reports under `message`, failure under `error`.
        let messageText = value("message").flatMap { try? container.decodeIfPresent(String.self, forKey: $0) } ?? nil
        let errorText = value("error").flatMap { try? container.decodeIfPresent(String.self, forKey: $0) } ?? nil
        message = messageText ?? errorText
        
        var rows: [PaymentHistoryModel]?
        
        for name in ["received", "payment_data", "payment_history", "data", "booking_data"] {
            
            guard let key = value(name),
                  let decoded = try? container.decodeIfPresent([PaymentHistoryModel].self, forKey: key) else {
                continue
            }
            
            rows = decoded
            break
        }
        
        received = rows
    }
}

struct PaymentHistoryModel: Identifiable, Decodable {
    
    let id = UUID()
    
    let amount: String?
    let paymentDate: String?
    let paymentMethod: String?
    let bookingId: String?
    
    private struct AnyKey: CodingKey {
        
        let stringValue: String
        var intValue: Int? { nil }
        
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }
    
    /// Amounts arrive as bare JSON numbers far more often than not in this API,
    /// and a plain `String?` decode throws on those — losing the whole row.
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: AnyKey.self)
        
        func text(_ names: String...) -> String? {
            
            for name in names {
                
                guard let key = AnyKey(stringValue: name) else { continue }
                
                if let value = try? container.decodeIfPresent(String.self, forKey: key),
                   !value.isEmpty {
                    return value
                }
                
                if let value = try? container.decodeIfPresent(Int.self, forKey: key) {
                    return String(value)
                }
                
                if let value = try? container.decodeIfPresent(Double.self, forKey: key) {
                    return String(value)
                }
            }
            
            return nil
        }
        
        amount = text("amount", "paid_amount", "total_amt", "base_fair")
        paymentDate = text("payment_date", "added_on", "date")
        paymentMethod = text("payment_method", "payment_mode")
        bookingId = text("booking_id")
    }
}

extension PaymentHistoryModel {
    
    var amountValue: Double {
        Double(amount ?? "") ?? 0
    }
    
    var amountDisplay: String {
        String(format: "£%.2f", amountValue)
    }
}
