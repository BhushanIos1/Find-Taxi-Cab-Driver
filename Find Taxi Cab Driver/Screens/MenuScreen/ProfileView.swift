//
//  ProfileView.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 06/03/26.
//

import SwiftUI
import SwiftfulLoadingIndicators

struct ProfileView: View {
    
    @EnvironmentObject
    private var router: AppRouter
    
    @EnvironmentObject
    private var toastManager: ToastManager
    
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    
    @State private var name = ""
    @State private var nameError: String?
    
    @State private var phone = ""
    @State private var phoneError: String?
    
    @State private var address = ""
    
    @State private var accountNumber = ""
    @State private var accountNumberError: String?
    
    @StateObject
    private var viewModel = ProfileViewModel()
    
    var body: some View {
        
        ZStack {
            
            VStack(spacing: 0) {
                
                ScrollView(showsIndicators: false) {
                    
                    VStack(spacing: 25) {
                        
                        headerSection
                        
                        AppTextField(
                            title: "Name",
                            text: $name,
                            error: nameError,
                            foregroundColor: Color(uiColor: .label)
                        )
                        
                        AppTextField(
                            title: "Mobile Number",
                            text: $phone,
                            error: phoneError,
                            keyboard: .phonePad,
                            foregroundColor: Color(uiColor: .label)
                        )
                        
                        AppTextField(
                            title: "Address",
                            text: $address,
                            error: nil,
                            foregroundColor: Color(uiColor: .label)
                        )
                        
                        AppTextField(
                            title: "Account Number",
                            text: $accountNumber,
                            error: accountNumberError,
                            foregroundColor: Color(uiColor: .label)
                        )
                        
                        bottomSection
                            .padding(.top, 25)
                    }
                }
                .padding(.vertical, 30)
                .padding(.horizontal, 20)
            }
            .disabled(viewModel.isLoading)
            
            if viewModel.isLoading {
                
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                
                LoadingIndicator(
                    animation: .circleTrim,
                    color: AppColors.primaryYellow,
                    size: .medium,
                    speed: .normal
                )
            }
        }
        .appNavigationBar(
            title: "Profile",
            leading: .back
        ) {
            router.pop()
        }
        .onAppear {
            viewModel.getDriverDetails()
        }
        .onChange(of: viewModel.driver) { driver in
            
            guard let driver else { return }
            
            name = driver.driverName ?? ""
            phone = driver.contactNo ?? ""
            address = driver.address ?? ""
            accountNumber = driver.bankAccountNumber ?? ""
            
            if let photo = driver.driverPhoto,
               let url = URL(string: "http://view.findtaxicab.com/admin/api/\(photo)") {
                
                Task {
                    do {
                        let (data, _) = try await URLSession.shared.data(from: url)
                        
                        if let image = UIImage(data: data) {
                            await MainActor.run {
                                selectedImage = image
                            }
                        }
                    } catch {
                        print(error)
                    }
                }
            }
        }
        .onChange(of: viewModel.registrationState) { state in
            
            guard let state else { return }
            
            switch state {
                
            case .success(let message):
                
                toastManager.showToast(
                    type: .success,
                    title: "Success",
                    subtitle: message
                )
                
                viewModel.errorMessage = nil
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    router.pop()
                }
                
            case .failure(let message):
                
                toastManager.showToast(
                    type: .error,
                    title: "Failed",
                    subtitle: message
                )
            }
            
            viewModel.registrationState = nil
        }
        .overlay(
            GlobalToastView()
                .environmentObject(toastManager)
        )
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
                
                Text(viewModel.driver?.email ?? AuthManager.shared.email)
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

private extension ProfileView {
    
    var bottomSection: some View {
        
        Button {
            
            viewModel.updateProfile(driverName: name, driverPhoto: selectedImage)
            
        } label: {
            Text("Update")
                .primaryButtonStyle()
        }
    }
}

#Preview {
    ProfileView()
}
