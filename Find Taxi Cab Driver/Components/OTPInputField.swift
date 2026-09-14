//
//  OTPInputField.swift
//  Find Taxi Cab Driver
//
//  Created by Claude on 13/09/26.
//

import SwiftUI

/// A tappable 4-box code field.
///
/// Replaces `SSOTPPinView` here, which renders its real `TextField` at
/// `.frame(width: 0, height: 0)` behind decorative boxes and only ever focuses
/// it from a delayed `.task` — so tapping a box did nothing, and the driver was
/// left poking at a field that felt dead. Its `.customNormalDigits` option also
/// replaces the system keyboard with the library's own keypad drawn into a
/// `.background`, which a sheet clips; and its `.numberPad` option maps, oddly,
/// to `.namePhonePad` — a letters keyboard for a digits-only code.
///
/// This one is a real text field the whole row focuses, with a true number pad.
struct OTPInputField: View {

    @Binding var code: String

    var count: Int = 4

    @FocusState private var isFocused: Bool

    var body: some View {

        ZStack {

            // The actual input, invisible but full-size behind the boxes, so a
            // tap anywhere on the row lands on it.
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .foregroundStyle(.clear)
                .tint(.clear)
                .accentColor(.clear)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .contentShape(Rectangle())
                .onChange(of: code) { newValue in

                    // Paste and predictive text can deliver more than digits.
                    let digits = newValue.filter(\.isNumber)

                    let trimmed = String(digits.prefix(count))

                    if trimmed != newValue {
                        code = trimmed
                    }

                    if trimmed.count == count {
                        isFocused = false
                    }
                }

            boxes
                .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = true
        }
        .onAppear {
            // A beat, so the sheet's own presentation animation finishes before
            // the keyboard comes up — otherwise both animate at once and the
            // field can lose focus on the way in.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                isFocused = true
            }
        }
    }
}

private extension OTPInputField {

    var boxes: some View {

        HStack(spacing: 12) {

            ForEach(0..<count, id: \.self) { index in
                box(at: index)
            }
        }
    }

    func box(at index: Int) -> some View {

        let digit = character(at: index)
        let isActive = isFocused && index == min(code.count, count - 1)

        return Text(digit)
            .font(AppFont.font(.semiBold, size: 24))
            .foregroundStyle(AppColors.primaryYellow)
            .frame(width: 56, height: 58)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isActive ? AppColors.primaryYellow : AppColors.primaryYellow.opacity(0.35),
                        lineWidth: isActive ? 2 : 1
                    )
            )
            .animation(.easeInOut(duration: 0.15), value: isActive)
    }

    func character(at index: Int) -> String {

        guard index < code.count else { return "" }

        let position = code.index(code.startIndex, offsetBy: index)
        return String(code[position])
    }
}

#Preview {
    OTPInputField(code: .constant("12"))
}
