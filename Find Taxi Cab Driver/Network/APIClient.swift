//
//  APIClient.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 21/03/26.
//

import Alamofire

final class APIClient {
    
    static let shared = APIClient()
    
    private let session: Session
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 30
        
        session = Session(
            configuration: config,
            interceptor: NetworkInterceptor.shared
        )
    }
}

extension APIClient {
    
    func request<T: Decodable>(
        _ endpoint: Endpoint,
        responseType: T.Type
    ) async throws -> T {
        
        let url = endpoint.baseURL + endpoint.path
        
        let request = session.request(
            url,
            method: .post,
            parameters: endpoint.parameters,
            encoding: endpoint.encoding
        )
        
        // ✅ Log request
        NetworkLogger.shared.logRequest(
            url: url,
            method: "POST",
            parameters: endpoint.parameters
        )
        
        let response = await request.serializingData().response
        
        // ✅ Log response
        NetworkLogger.shared.logResponse(
            data: response.data,
            response: response.response,
            error: response.error
        )
        
        // ✅ HANDLE SERVER STATUS FIRST (VERY IMPORTANT)
        if let statusCode = response.response?.statusCode,
           !(200...299).contains(statusCode) {
            
            throw NetworkError.serverMessage("Server error: \(statusCode)")
        }
        
        // ✅ HANDLE EMPTY RESPONSE (YOUR CURRENT ISSUE)
        guard let data = response.data, !data.isEmpty else {
            throw NetworkError.serverMessage("Empty response from server")
        }
        
        do {
            // ✅ First try standard wrapper
            if let decoded = try? JSONDecoder().decode(APIResponse<T>.self, from: data) {
                
                if decoded.isSuccess {
                    
                    if let data = decoded.data {
                        return data
                    }
                    
                    if T.self == EmptyResponse.self {
                        return EmptyResponse() as! T
                    }
                }
            }
            
            // ✅ SECOND: Try direct decoding (YOUR CASE)
            let direct = try JSONDecoder().decode(T.self, from: data)
            return direct
            
        } catch {
            print("❌ DECODING ERROR:", error)
            throw NetworkError.decodingError
        }
    }
}

extension APIClient {
    
    func uploadProfile(driverName: String, driverPhoto: UIImage?) async throws -> CommonResponse {
        
        let url = "http://view.findtaxicab.com/admin/api/update_driver_profile"
        
        print("""
        ==============================
        🚀 PROFILE UPDATE REQUEST
        ==============================
        URL: \(url)
        
        driver_id: \(AuthManager.shared.driverId)
        driverName: \(driverName)
        ==============================
        """)
        
        if let image = driverPhoto,
           let imageData = image.jpegData(compressionQuality: 0.7) {
            
            let base64 = imageData.base64EncodedString()
            
            print("""
            📸 IMAGE INFO
            Size: \(imageData.count / 1024) KB
            Base64 Length: \(base64.count)
            Base64 Preview:
            \(base64.prefix(100))
            """)
        } else {
            print("📸 No image selected")
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            
            AF.upload(
                multipartFormData: { multipart in
                    
                    multipart.append(
                        Data(AuthManager.shared.driverId.utf8),
                        withName: "driver_id"
                    )
                    
                    multipart.append(
                        Data(driverName.utf8),
                        withName: "driverName"
                    )
                    
                    if let image = driverPhoto,
                       let imageData = image.jpegData(compressionQuality: 0.7) {
                        
                        let base64 = imageData.base64EncodedString()
                        
                        multipart.append(
                            Data(base64.utf8),
                            withName: "driver_photo"
                        )
                        
                        multipart.append(
                            Data("".utf8),
                            withName: "license_photo"
                        )
                        
                        multipart.append(
                            Data("".utf8),
                            withName: "badge_photo"
                        )
                        
                        multipart.append(
                            Data("".utf8),
                            withName: "vehicle_insuarance_photo"
                        )
                    }
                },
                to: url,
                method: .post
            )
            .responseData { response in
                
                print("""
                ==============================
                📥 PROFILE UPDATE RESPONSE
                ==============================
                URL: \(url)
                STATUS: \(response.response?.statusCode ?? 0)
                ==============================
                """)
                
                if let data = response.data {
                    
                    print("""
                    📄 RAW RESPONSE
                    \(String(data: data, encoding: .utf8) ?? "Invalid UTF8")
                    """)
                } else {
                    
                    print("❌ NO RESPONSE DATA")
                }
                
                if let error = response.error {
                    
                    print("""
                    ❌ REQUEST FAILED
                    \(error)
                    ==============================
                    """)
                    
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let data = response.data else {
                    
                    continuation.resume(
                        throwing: NetworkError.serverMessage(
                            "Empty response"
                        )
                    )
                    return
                }
                
                do {
                    
                    let decoded =
                    try JSONDecoder().decode(
                        CommonResponse.self,
                        from: data
                    )
                    
                    print("""
                    ✅ DECODE SUCCESS
                    result: \(decoded.result ?? "")
                    message: \(decoded.message ?? "")
                    ==============================
                    """)
                    
                    continuation.resume(returning: decoded)
                    
                } catch {
                    
                    print("""
                    ❌ DECODE FAILED
                    \(error)
                    
                    RAW:
                    \(String(data: data, encoding: .utf8) ?? "")
                    ==============================
                    """)
                    
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

extension APIClient {
    
    func updateBankDetails(
        accountHolderName: String,
        bankName: String,
        sortCode: String,
        accountNumber: String
    ) async throws -> CommonResponse {
        
        let url = "http://view.findtaxicab.com/admin/api/driver_update_bank"
        
        print("""
        ==============================
        🚀 UPDATE BANK REQUEST
        ==============================
        URL: \(url)
        
        driver_id: \(AuthManager.shared.driverId)
        bank_account_name: \(accountHolderName)
        bank_name: \(bankName)
        bank_code: \(sortCode)
        bank_account_number: \(accountNumber)
        ==============================
        """)
        
        return try await withCheckedThrowingContinuation { continuation in
            
            session.upload(
                multipartFormData: { multipart in
                    
                    multipart.append(
                        Data(AuthManager.shared.driverId.utf8),
                        withName: "driver_id"
                    )
                    
                    multipart.append(
                        Data(accountHolderName.utf8),
                        withName: "bank_account_name"
                    )
                    
                    multipart.append(
                        Data(bankName.utf8),
                        withName: "bank_name"
                    )
                    
                    multipart.append(
                        Data(sortCode.utf8),
                        withName: "bank_code"
                    )
                    
                    multipart.append(
                        Data(accountNumber.utf8),
                        withName: "bank_account_number"
                    )
                },
                to: url,
                method: .post
            )
            .responseData { response in
                
                print("""
                ==============================
                📥 UPDATE BANK RESPONSE
                ==============================
                STATUS: \(response.response?.statusCode ?? 0)
                ==============================
                """)
                
                if let data = response.data {
                    
                    print("""
                    RAW RESPONSE:
                    \(String(data: data, encoding: .utf8) ?? "")
                    """)
                }
                
                if let error = response.error {
                    
                    print("❌ UPDATE BANK ERROR")
                    print(error)
                    
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let data = response.data else {
                    
                    continuation.resume(
                        throwing: NetworkError.serverMessage(
                            "Empty Response"
                        )
                    )
                    return
                }
                
                do {
                    
                    let decoded = try JSONDecoder().decode(
                        CommonResponse.self,
                        from: data
                    )
                    
                    continuation.resume(returning: decoded)
                    
                } catch {
                    
                    print("❌ DECODING ERROR")
                    print(error)
                    
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

extension APIClient {
    
    func getDriverDetails() async throws -> DriverDetailsResponse {
        
        let url = "http://view.findtaxicab.com/admin/api/get_driver_details"
        
        print("""
        ==============================
        🚀 DRIVER DETAILS API
        URL: \(url)
        
        driver_id:
        \(AuthManager.shared.driverId)
        ==============================
        """)
        
        return try await withCheckedThrowingContinuation { continuation in
            
            AF.upload(
                multipartFormData: { multipart in
                    
                    multipart.append(
                        Data(AuthManager.shared.driverId.utf8),
                        withName: "driver_id"
                    )
                },
                to: url,
                method: .post
            )
            .validate()
            .responseDecodable(of: DriverDetailsResponse.self) { response in
                
                print("""
                ==============================
                📥 DRIVER DETAILS RESPONSE
                Status:
                \(response.response?.statusCode ?? 0)
                ==============================
                """)
                
                switch response.result {
                    
                case .success(let value):
                    
                    print("✅ SUCCESS")
                    print(value)
                    
                    continuation.resume(returning: value)
                    
                case .failure(let error):
                    
                    print("❌ ERROR")
                    print(error)
                    
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

struct EmptyResponse: Decodable {
    init() {}
}
