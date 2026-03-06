//
//  CustomNavigationBar.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 26/02/26.
//

import SwiftUI

enum NavBarLeadingType {
    case back
    case menu
    case none
}

struct CustomNavigationBar: View {
    
    let title: String
    let leadingType: NavBarLeadingType
    
    var onMenuTap: (() -> Void)?
    var toggleBinding: Binding<Bool>? = nil
    
    @EnvironmentObject private var router: AppRouter
    
    var body: some View {
        
        HStack {
            
            leadingView
            
            Spacer()
            
            Text(title)
                .font(AppFont.font(.medium, size: 20))
                .foregroundStyle(.white)
            
            Spacer()
            
            trailingView
        }
        .frame(height: 58)
        .background(AppColors.primaryYellow)
    }
}

private extension CustomNavigationBar {
    
    @ViewBuilder
    var leadingView: some View {
        
        switch leadingType {
            
        case .back:
            Button {
                router.pop()
            } label: {
                Image(systemName: "arrow.backward")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
            }
            .frame(width: 56, height: 56)
            .contentShape(Rectangle())
            
        case .menu:
            Button {
                onMenuTap?()
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 24, height: 24)
            }
            .frame(width: 56, height: 56)
            .contentShape(Rectangle())
            
        case .none:
            Color.clear
                .frame(width: 50)
        }
    }
}

private extension CustomNavigationBar {

    @ViewBuilder
    var trailingView: some View {

        if let toggleBinding {

            Toggle("", isOn: toggleBinding)
                .labelsHidden()
                .toggleStyle(AppSwitchToggleStyle())
                .padding(.horizontal, 20)

        } else {

            Color.clear
                .frame(width: 56)
        }
    }
}

#Preview {
    CustomNavigationBar(title: "", leadingType: .none, onMenuTap: nil, toggleBinding: .constant(true))
}
