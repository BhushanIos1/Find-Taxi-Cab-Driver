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
        
        Text(item.statusDisplay)
            .font(AppFont.font(.medium, size: 16))
            .foregroundColor(statusColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
    }
}

private extension JobHistoryCell {
    
    var statusColor: Color {
        
        switch item.assignStatus?.lowercased() {
        case "complete":
            return .green
        case "cancel":
            return .red
        default:
            return AppColors.primaryYellow
        }
    }
}

private extension JobHistoryCell {
    
    var detailsSection: some View {
        
        VStack(spacing: 0) {
            
            detailRow("Job Number", item.bookingId ?? "—")
            detailRow("Job Date", item.date ?? "—")
            detailRow("Time", item.time ?? "—")
            detailRow("Pickup Location", item.pickup ?? "—")
            detailRow("Drop Location", item.drop ?? "—")
            detailRow("Payment Mode", item.paymentMethod?.capitalized ?? "—")
            detailRow("Special Message", item.specialMessage ?? "")
            detailRow("Special Need", item.specialNeed ?? "—")
            detailRow("Fare", item.fareDisplay, showDivider: false)
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
        bookingId: "932",
        assignStatus: "abandon",
        date: "07/02/2026",
        time: "13:39:37",
        pickup: "Hindmotor, Uttarpara, West Bengal, India",
        drop: "Rishra, Pandit Satghara, West Bengal, India",
        paymentMethod: "Cash",
        baseFare: "0",
        specialMessage: "",
        specialNeed: "No"
    ))
}
