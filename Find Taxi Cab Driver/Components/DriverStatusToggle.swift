//
//  DriverStatusToggle.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 04/03/26.
//

import SwiftUI

enum DriverStatus: String {
    case free = "free"
    case busy = "busy"
}

struct DriverStatusToggle: View {
    
    @Binding var status: DriverStatus
    
    let onToggle: () -> Void
    
    private let height: CGFloat = 90
    private let circleSize: CGFloat = 82
    private let horizontalPadding: CGFloat = 16
    
    var body: some View {
        
        GeometryReader { geo in
            toggleBody(width: geo.size.width)
        }
        .frame(height: height)
    }
}

private extension DriverStatusToggle {
    
    func toggleBody(width: CGFloat) -> some View {
        
        /// ✅ Safe movement limits
        let leftOffset =
        -width/2 + circleSize/2 + horizontalPadding
        
        let rightOffset =
        width/2 - circleSize/2 - horizontalPadding
        
        return ZStack {
            
            backgroundCapsule
            
            statusCircle(
                offset: status == .free
                ? leftOffset
                : rightOffset
            )
        }
        .contentShape(RoundedRectangle(cornerRadius: 20))
        .onTapGesture {
            Haptic.medium()
            onToggle()
        }
    }
}

private extension DriverStatusToggle {
    
    var backgroundCapsule: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(.black.opacity(0.18))
    }
}

private extension DriverStatusToggle {
    
    func statusCircle(offset: CGFloat) -> some View {
        
        Circle()
            .fill(status == .free
                  ? Color(hex: "#0DF705")
                  : Color(hex: "#FE0000"))
            .frame(width: circleSize,
                   height: circleSize)
            .overlay(statusText)
            .offset(x: offset)
            .animation(
                .spring(
                    response: 0.35,
                    dampingFraction: 0.8
                ),
                value: status
            )
    }
}

private extension DriverStatusToggle {
    
    var statusText: some View {
        Text(status == .free ? "Free" : "Busy")
            .font(AppFont.font(.regular, size: 16))
            .foregroundColor(.black)
    }
}
