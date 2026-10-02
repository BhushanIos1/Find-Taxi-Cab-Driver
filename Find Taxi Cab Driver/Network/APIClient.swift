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
            // Decode the response as what the caller actually asked for, first.
            //
            // This used to try `APIResponse<T>` ahead of the direct decode, and
            // that quietly broke every endpoint answering
            // `{"result": "success", "data": { ...something else... }}`.
            // `/miles_cal` is the clearest case: the wrapper matched, saw
            // `result == "success"`, then decoded its *inner* `data` object as
            // the caller's `CommonResponse`. Every field on that type is
            // optional, so it "succeeded" — returning an empty value with
            // `result == nil`. The caller read that as a failure and reported
            // "Could Not Submit Fare" for a fare the server had accepted.
            //
            // Trying T first means the envelope is only consulted when the
            // response genuinely isn't the shape the caller expected.
            if let direct = try? JSONDecoder().decode(T.self, from: data) {
                return direct
            }
            
            if let decoded = try? JSONDecoder().decode(APIResponse<T>.self, from: data) {

                if decoded.isSuccess {

                    if let data = decoded.data {
                        print("ℹ️ Decoded via APIResponse envelope")
                        return data
                    }

                    if T.self == EmptyResponse.self {
                        return EmptyResponse() as! T
                    }
                }
            }

            // Confirmed on `change_book_status`: the server sometimes appends
            // a raw PHP warning straight onto the end of an otherwise-valid
            // body with no separator —
            // `{"result":"success","message":"Booking Cancelled"}Error: ...`.
            // The response the server actually meant to send is sitting right
            // there at the start; only the junk tacked on after it breaks
            // `JSONDecoder`. Before giving up, retry against just the
            // well-formed leading JSON object/array, so a genuine success on
            // the server isn't reported to the UI as a decoding failure.
            if let repaired = Self.leadingJSONObject(in: data) {

                if let direct = try? JSONDecoder().decode(T.self, from: repaired) {
                    print("⚠️ Decoded after trimming trailing non-JSON content the server appended to the response")
                    return direct
                }

                if let decoded = try? JSONDecoder().decode(APIResponse<T>.self, from: repaired),
                   decoded.isSuccess {

                    if let data = decoded.data {
                        print("⚠️ Decoded via APIResponse envelope after trimming trailing non-JSON content")
                        return data
                    }

                    if T.self == EmptyResponse.self {
                        return EmptyResponse() as! T
                    }
                }
            }

            // Neither shape fits, even after repair — let the real error surface.
            let direct = try JSONDecoder().decode(T.self, from: data)
            return direct

        } catch {
            print("❌ DECODING ERROR:", error)
            throw NetworkError.decodingError
        }
    }

    /// Finds the first complete top-level JSON object or array in `data` and
    /// returns just those bytes, discarding anything appended after it.
    /// Returns `nil` when there's nothing to trim (already-valid JSON, or no
    /// JSON found at all) — callers should treat that as "no repair possible",
    /// not "the response is now empty".
    private static func leadingJSONObject(in data: Data) -> Data? {

        guard let text = String(data: data, encoding: .utf8),
              let openIndex = text.firstIndex(where: { $0 == "{" || $0 == "[" }) else {
            return nil
        }

        let opening = text[openIndex]
        let closing: Character = opening == "{" ? "}" : "]"

        var depth = 0
        var insideString = false
        var isEscaped = false
        var closeIndex: String.Index?

        for index in text[openIndex...].indices {

            let character = text[index]

            if isEscaped {
                isEscaped = false
                continue
            }

            if character == "\\" {
                isEscaped = true
                continue
            }

            if character == "\"" {
                insideString.toggle()
                continue
            }

            guard !insideString else { continue }

            if character == opening {
                depth += 1
            } else if character == closing {
                depth -= 1
                if depth == 0 {
                    closeIndex = index
                    break
                }
            }
        }

        guard let closeIndex else { return nil }

        let jsonSlice = text[openIndex...closeIndex]

        // Nothing was actually appended after it — same bytes either way, so
        // retrying the decode against this would just fail the same way again.
        guard jsonSlice.utf8.count != text.utf8.count else { return nil }

        return Data(jsonSlice.utf8)
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
