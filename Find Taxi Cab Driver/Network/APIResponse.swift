//
//  APIResponse.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 21/03/26.
//

struct APIResponse<T: Decodable>: Decodable {
    
    let result: String?
    let message: String?
    let data: T?
    let success: Int?
    
    var isSuccess: Bool {
        if result == "success" { return true }
        if success == 1 || success == 200 { return true }
        return false
    }
}

struct CommonResponse: Decodable {

    let result: String?
    let message: String?

    enum CodingKeys: String, CodingKey {
        case result, message, error
    }

    /// This backend reports success under `message` but failure under `error`,
    /// and not every endpoint sends both. Android handles it per-call — e.g.
    /// `RouteDetailsActivity.giveFeedback()` reads `message` on success and
    /// `getString("error")` on failure — so a client reading only `message`
    /// loses the reason for every failed call and shows a generic fallback in
    /// its place. That is why a rejected `/miles_cal` only ever said "Could Not
    /// Submit Fare" instead of what the server actually objected to.
    init(from decoder: Decoder) throws {

        let container = try decoder.container(keyedBy: CodingKeys.self)

        result = try container.decodeIfPresent(String.self, forKey: .result)

        message = try container.decodeIfPresent(String.self, forKey: .message)
            ?? container.decodeIfPresent(String.self, forKey: .error)
    }

    init(result: String?, message: String?) {
        self.result = result
        self.message = message
    }
}
