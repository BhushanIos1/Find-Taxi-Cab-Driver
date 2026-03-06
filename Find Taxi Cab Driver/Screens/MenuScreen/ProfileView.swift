//
//  ProfileView.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 06/03/26.
//

import SwiftUI

struct ProfileView: View {
    
    @EnvironmentObject
    private var router: AppRouter
    
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    
    @State private var name = ""
    @State private var nameError: String?
    
    @State private var phone = ""
    @State private var phoneError: String?
    
    @State private var address = ""
    
    @State private var accountNumber = ""
    @State private var accountNumberError: String?
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            ScrollView(showsIndicators: false) {
                
                VStack(spacing: 25) {
                    
                    headerSection
                    
                    AppTextField(title: "Name", text: $name, error: nameError)
                    AppTextField(title: "Mobile Number", text: $phone, error: phoneError, keyboard: .phonePad)
                    AppTextField(title: "Address", text: $address, error: nil)
                    AppTextField(title: "Account Number", text: $accountNumber, error: accountNumberError)
                }
            }
            .padding(.vertical, 30)
            .padding(.horizontal, 20)
        }
        .appNavigationBar(
            title: "Profile",
            leading: .back) {
                router.pop()
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
    }
}

private extension ProfileView {
    
    var headerSection: some View {
        
        ZStack(alignment: .topTrailing) {
            
            VStack(spacing: 20) {
                
                profileImage
                
                Text("gnabieurocabs@hotmail.com.uk")
                    .font(.system(size: 20, weight: .medium))
            }
            .padding(.top, 20)
            
            editButton
        }
    }
    
    var profileImage: some View {
        
        Group {
            
            if let image = selectedImage {
                
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                
            } else {
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFill()
                    .padding(30)
                    .foregroundColor(.white)
                    .background(Color.gray)
            }
        }
        .frame(width: 120, height: 120)
        .clipShape(Circle())
    }
    
    var editButton: some View {
        
        Button {
            showImagePicker = true
        } label: {
            
            Image(systemName: "pencil")
                .foregroundColor(.primary)
                .font(AppFont.font(.bold, size: 25))
        }
        .offset(x: 20, y: 20)
    }
}

#Preview {
    ProfileView()
}
