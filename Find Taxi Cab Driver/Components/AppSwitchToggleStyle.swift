//
//  AppSwitchToggleStyle.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 04/03/26.
//

import SwiftUI

struct AppSwitchToggleStyle: ToggleStyle {
    
    func makeBody(configuration: Configuration) -> some View {
        
        HStack {
            
            configuration.label
            
            ZStack(alignment: configuration.isOn ? .trailing : .leading) {
                
                // Background
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        configuration.isOn
                        ? Color.red.opacity(0.2)
                        : Color.black.opacity(0.10)
                    )
                    .frame(width: 62, height: 24)
                
                Circle()
                    .fill(
                          configuration.isOn
                          ? Color.red.opacity(0.6)
                          : Color.white)
                    .frame(width: 32, height: 32)
                    .shadow(color: .black.opacity(0.25),
                            radius: 4,
                            x: 0,
                            y: 2)
            }
            .animation(.easeInOut(duration: 0.25),
                       value: configuration.isOn)
            .onTapGesture {
                configuration.isOn.toggle()
            }
        }
    }
}

#Preview {
    Toggle("", isOn: .constant(true))
        .labelsHidden()
        .toggleStyle(AppSwitchToggleStyle())
}
