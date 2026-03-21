//
//  ActionButtonView.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 21/03/26.
//

import SwiftUI

struct ActionButtonView: View {
    
    let title: String
    let backgroundColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.font(.medium, size: 18))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(backgroundColor)
                .foregroundColor(.white)
                .cornerRadius(6)
        }
    }
}

#Preview {
    ActionButtonView(
        title: "ACCEPT",
        backgroundColor: .green
    ) {
    }
}
