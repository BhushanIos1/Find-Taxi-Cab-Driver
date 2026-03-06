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
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(
            color: .black.opacity(0.15),
            radius: 8,
            x: 0,
            y: 4
        )
        .padding(.horizontal)
        .background(
            colorScheme == .dark
            ? Color(.systemGray6)
            : Color(.white)
        )
        .shadow(
            color: .black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}

private extension JobHistoryCell {
    
    var statusHeader: some View {
        
        Text(item.status)
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(statusColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
    }
}

private extension JobHistoryCell {
    
    var statusColor: Color {
        
        switch item.status.lowercased() {
        case "completed":
            return .green
        case "abandoned":
            return .orange
        case "cancelled":
            return .red
        default:
            return .primary
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
                    .foregroundColor(.secondary)
                
                Text(value)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .font(.system(size: 14))
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            
            if showDivider {
                Divider()
            }
        }
    }
}

private extension JobHistoryCell {
    
    var cardBackground: some View {
        Color(uiColor: .secondarySystemBackground)
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
