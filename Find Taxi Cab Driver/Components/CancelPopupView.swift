//
//  CancelPopupView.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 21/03/26.
//

import SwiftUI

struct CancelPopupView: View {
    
    @Environment(\.colorScheme) var colorScheme
    
    @Binding var isPresented: Bool
    
    let title: String
    let placeholder: String
    let buttonTitle: String
    let onSubmit: (String) -> Void
    
    @State private var inputText: String = ""
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        
        ZStack {
            
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            VStack(alignment: .leading, spacing: 20) {
                
                Text(title)
                    .multilineTextAlignment(.leading)
                    .font(AppFont.font(.medium, size: 30))
                
                VStack(spacing: 4) {
                    
                    TextField(placeholder, text: $inputText)
                        .focused($isFocused)
                        .font(AppFont.font(.regular, size: 18))
                        .tint(AppColors.primaryYellow)
                    
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(isFocused ? AppColors.primaryYellow : .gray.opacity(0.5))
                        .animation(.easeInOut(duration: 0.2), value: isFocused)
                }
                
                Button {
                    submitAction()
                } label: {
                    Text(buttonTitle)
                        .font(AppFont.font(.medium, size: 18))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(7)
                }
                .disabled(inputText.isEmpty)
            }
            .padding(20)
            .background(colorScheme == .dark
                        ? Color(.systemGray6)
                        : Color(.white))
            .cornerRadius(6)
            .padding(.horizontal, 20)
        }
        .transition(.opacity.combined(with: .scale))
    }
}

// MARK: - Actions
private extension CancelPopupView {
    
    func submitAction() {
        guard !inputText.isEmpty else { return }
        onSubmit(inputText)
        dismiss()
    }
    
    func dismiss() {
        isPresented = false
    }
}

#Preview {
    CancelPopupView(isPresented: .constant(false),
                    title: "Reason For Cancellation :",
                    placeholder: "Type here...",
                    buttonTitle: "SUBMIT"
    ) { text in
        print("User Input:", text)
    }
}
