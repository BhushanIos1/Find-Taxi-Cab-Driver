//
//  BookingListCell.swift
//  Find Taxi Cab
//
//  Created by Bhushan Kumar on 01/03/26.
//

import SwiftUI

struct JobHistoryCell: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    let item: JobHistoryModel
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            statusHeader
            
            Divider()
            
            detailsSection
        }
        .background(
            colorScheme == .dark
            ? Color(.systemGray6)
            : Color(.white)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(AppColors.yellowBorder, lineWidth: 0.8)
        )
        .shadow(
            color: .black.opacity(0.07),
            radius: 4,
            x: 0,
            y: 8
        )
    }
}

private extension JobHistoryCell {
    
    var statusHeader: some View {
        
        Text(item.status)
            .font(AppFont.font(.medium, size: 16))
            .foregroundColor(statusColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
    }
}

private extension JobHistoryCell {
    
    var statusColor: Color {
        
        switch item.status.lowercased() {
        case "completed":
            return .green
        case "abandoned":
            return AppColors.primaryYellow
        case "cancelled":
            return .red
        default:
            return AppColors.primaryYellow
        }
    }
}

private extension JobHistoryCell {
    
    var detailsSection: some View {
        
        VStack(spacing: 0) {
            
            detailRow("Job Number", item.jobNumber)
            detailRow("Job Date", item.jobDate)
            detailRow("Time", item.time)
            detailRow("Pickup Location", item.pickup)
            detailRow("Drop Location", item.drop)
            detailRow("Payment Mode", item.paymentMode)
            detailRow("Special Message", item.specialMessage)
            detailRow("Special Need", item.specialNeed)
            detailRow("Fare", item.fare, showDivider: false)
        }
    }
}

private extension JobHistoryCell {
    
    func detailRow(
        _ title: String,
        _ value: String,
        showDivider: Bool = true
    ) -> some View {
        
        VStack(spacing: 0) {
            
            HStack(alignment: .top) {
                
                Text("\(title):")
                    .frame(width: 140, alignment: .leading)
                    .foregroundColor(Color(hex: "#373737"))
                
                Text(value)
                    .foregroundColor(Color(hex: "#373737"))
                
                Spacer()
            }
            .font(AppFont.font(.regular, size: 14))
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            
            if showDivider {
                Divider()
                    .foregroundStyle(Color(hex: "#EFEFEF"))
            }
        }
    }
}

#Preview {
    JobHistoryCell(item: JobHistoryModel(
        status: "Abandoned",
        jobNumber: "932",
        jobDate: "07/02/2026",
        time: "13:39:37",
        pickup: "Hindmotor, Uttarpara, West Bengal, India",
        drop: "Rishra, Pandit Satghara, West Bengal, India",
        paymentMode: "Cash",
        specialMessage: "",
        specialNeed: "No",
        fare: "£ 0"
    ))
}
