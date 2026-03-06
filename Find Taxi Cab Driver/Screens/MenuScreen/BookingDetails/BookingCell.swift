//
//  BookingCell.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 07/03/26.
//

import SwiftUI

struct BookingCell: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    let item: BookingDetailsModel
    
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

private extension BookingCell {
    
    var statusHeader: some View {
        
        Text(item.status)
            .font(AppFont.font(.medium, size: 16))
            .foregroundColor(statusColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
    }
}

private extension BookingCell {
    
    var statusColor: Color {
        
        switch item.status.lowercased() {
        case "completed":
            return .green
        case "abandoned":
            return AppColors.primaryYellow
        case "cancelled":
            return .red
        default:
            return .black
        }
    }
}

private extension BookingCell {
    
    var detailsSection: some View {
        
        VStack(spacing: 0) {
            
            detailRow("Booking Id", item.bookingId)
            detailRow("Customer Mobile", item.customerMobile)
            detailRow("Source Address", item.pickup)
            detailRow("Dest Address", item.drop)
            detailRow("Booking Date", item.bookingDate)
            detailRow("Booking Status", item.bookingStatus)
        }
    }
}

private extension BookingCell {
    
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
    BookingCell(item: BookingDetailsModel(
        status: "Booking Page",
        bookingId: "932",
        customerMobile: "1234567890",
        pickup: "Hindmotor, Uttarpara, West Bengal, India",
        drop: "Rishra, Pandit Satghara, West Bengal, India",
        bookingDate: "2026-02-07   13:39:00",
        bookingStatus: "Abandon"
    ))
}
