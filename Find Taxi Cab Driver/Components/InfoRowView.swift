//
//  InfoRowView.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 21/03/26.
//

import SwiftUI

struct InfoRowView: View {
    
    let title: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 22) {
            
            Text(title)
                .font(AppFont.font(.semiBold, size: 16))
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(AppFont.font(.regular, size: 16))
                .multilineTextAlignment(.leading)
        }
    }
}

#Preview {
    InfoRowView(title: "", value: "")
}
