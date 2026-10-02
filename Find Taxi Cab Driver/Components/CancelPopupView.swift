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

    /// Driven by the caller's in-flight cancel request — disables SUBMIT and
    /// swaps its label so a slow network can't be mistaken for a dead button.
    var isSubmitting: Bool = false

    /// The server's own `change_book_status` failure message (e.g. "Booking
    /// Can Not Be Proceeded, Something Went Wrong"). Shown inline rather than
    /// only as a toast: the popup used to close the instant SUBMIT was tapped,
    /// so a failure landed on a screen with no popup left to explain itself,
    /// and the driver had no way to retry without reopening CANCEL and retyping
    /// the reason. Now the popup stays open and SUBMIT itself is the retry.
    var errorMessage: String? = nil

    @State private var inputText: String = ""
    
    /// A reason is required — this is what's shown when SUBMIT is tapped on an
    /// empty field. Cleared the moment the driver starts typing, so it never
    /// lingers on screen after the thing it was complaining about is fixed.
    @State private var showEmptyWarning = false
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        
        ZStack {
            
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture {
                    // A request in flight shouldn't be abandoned by a stray tap
                    // outside the card — there's nothing left to retry with
                    // once the popup and its typed reason are gone.
                    guard !isSubmitting else { return }
                    dismiss()
                }
            
            VStack(alignment: .leading, spacing: 20) {
                
                Text(title)
                    .multilineTextAlignment(.leading)
                    .font(AppFont.font(.medium, size: 30))
                
                VStack(alignment: .leading, spacing: 6) {
                    
                    VStack(spacing: 4) {
                        
                        TextField(placeholder, text: $inputText)
                            .focused($isFocused)
                            .font(AppFont.font(.regular, size: 18))
                            .tint(AppColors.primaryYellow)
                            .onChange(of: inputText) { _ in
                                showEmptyWarning = false
                            }
                        
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(
                                showEmptyWarning
                                ? .red
                                : (isFocused ? AppColors.primaryYellow : .gray.opacity(0.5))
                            )
                            .animation(.easeInOut(duration: 0.2), value: isFocused)
                    }
                    
                    if showEmptyWarning {

                        Text("Please enter a reason for cancellation.")
                            .font(AppFont.font(.regular, size: 13))
                            .foregroundColor(.red)
                            .transition(.opacity)
                    }

                    if let errorMessage {

                        Text(errorMessage)
                            .font(AppFont.font(.regular, size: 13))
                            .foregroundColor(.red)
                            .transition(.opacity)
                    }
                }

                Button {
                    submitAction()
                } label: {
                    Text(isSubmitting ? "Cancelling…" : buttonTitle)
                        .font(AppFont.font(.medium, size: 18))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(7)
                        .opacity(isSubmitting ? 0.6 : 1)
                }
                .disabled(isSubmitting)
            }
            .padding(20)
            .background(colorScheme == .dark
                        ? Color(.systemGray6)
                        : Color(.white))
            .cornerRadius(6)
            .padding(.horizontal, 20)
            .animation(.easeInOut(duration: 0.2), value: showEmptyWarning)
            .animation(.easeInOut(duration: 0.2), value: errorMessage)
        }
        .transition(.opacity.combined(with: .scale))
    }
}

// MARK: - Actions
private extension CancelPopupView {
    
    func submitAction() {

        guard !isSubmitting else { return }

        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {
            withAnimation {
                showEmptyWarning = true
            }
            return
        }

        // Dismissal is the caller's call now — only a confirmed server success
        // closes this popup, via `isPresented`. A failure leaves it open with
        // `errorMessage` set, so the driver can retry without retyping.
        onSubmit(trimmed)
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
