//
//  Endpoint.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 21/03/26.
//

import Alamofire

protocol Endpoint {
    var path: String { get }
    var parameters: Parameters? { get }
}

extension Endpoint {
    
    var baseURL: String {
        return "http://view.findtaxicab.com/admin/api"
    }
    
    var method: HTTPMethod {
        return .post
    }
    
    var encoding: ParameterEncoding {
        return URLEncoding.httpBody
    }
}

enum DriverAPI: Endpoint {
    
    case login(email: String,
               password: String,
               token: String)
    case register(
        name: String,
        email: String,
        phone: String,
        password: String,
        address: String
    )
    case logout
    case changeStatus(status: String)
    case updateLocation(lat: String, lng: String)
    case bookingList
}

extension DriverAPI {
    
    var path: String {
        switch self {
        case .login: return "/driver_login"
        case .register: return "/register_driver"
        case .logout: return "/logout_driver"
        case .changeStatus: return "/change_status"
        case .updateLocation: return "/driver_location"
        case .bookingList: return "/driver_book_list"
        }
    }
    
    var parameters: Parameters? {
        
        let driverId = AuthManager.shared.driverId
        
        switch self {
            
        case .login(let email, let password, let token):
            return [
                "email": email,
                "password": password,
                "token": token,
                "device_type": "ios"
            ]
            
        case .register(_, let email, let phone, let password, _):
            return [
                "email": email,
                "contact_no": phone,
                "password": password
            ]
            
        case .logout:
            return ["driver_id": driverId]
            
        case .changeStatus(let status):
            return [
                "driver_id": driverId,
                "status": status
            ]
            
        case .updateLocation(let lat, let lng):
            return [
                "driver_id": driverId,
                "latitude": lat,
                "longitude": lng,
                "date": "\(Date())",
                "time": "\(Date())",
                "booking_id": ""
            ]
            
        case .bookingList:
            return ["driver_id": driverId]
        }
    }
}
