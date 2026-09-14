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
    case forgotPassword(email: String)
    case changePassword(password: String)
    case updateProfile(
        driverName: String,
        driverPhoto: String?,
        licensePhoto: String?,
        vehicleInsurancePhoto: String?,
        badgePhoto: String?
    )
    case logout
    case changeStatus(status: String)
    case getDriverDetails
    case updateLocation(lat: String, lng: String, bookingId: String = "")
    case updateFCMToken(token: String)
    case lastBooking
    case bookingList
    case getBookingData(bookingId: String)
    case changeBookingStatus(bookingId: String, status: String, cancelMessage: String?)
    /// `/miles_cal` — the driver submits the trip's final price after COMPLETED.
    /// Until this lands the rider's `get_fair` has nothing to show and payment
    /// can't proceed, so it's the step that closes out a trip financially.
    case submitFinalFare(
        bookingId: String,
        price: String,
        tollCharge: String,
        feedback: String,
        customerRate: String
    )

    case sendRideOTP(bookingId: String)
    case verifyRideOTP(bookingId: String, otp: String)
    case updateBankDetails(parameters: Parameters)
    case paymentHistory
    case customerFeedback
    case checkAccountStatus
    case getDriverLatLng
    case getDriverStatus
    case getNearClients(lat: String, lng: String)
    case driverFeedback(bookingId: String, feedback: String, rate: String)
}

extension DriverAPI {
    
    var path: String {
        switch self {
        case .login: return "/driver_login"
        case .register: return "/register_driver"
        case .forgotPassword: return "/reset_pass"
        case .changePassword: return "/driver_change_pass"
        case .updateProfile: return "/update_driver_profile"
        case .logout: return "/logout_driver"
        case .getDriverDetails: return "/get_driver_details"
        case .changeStatus: return "/change_status"
        case .updateLocation: return "/driver_location"
        case .updateFCMToken: return "/update_drivertoken"
        case .lastBooking: return "/driver_last_book"
        case .bookingList: return "/driver_book_list"
        case .getBookingData: return "/get_bookdata"
        case .changeBookingStatus: return "/change_book_status"
        case .submitFinalFare: return "/miles_cal"
        case .sendRideOTP: return "/send_ride_otp"
        case .verifyRideOTP: return "/verify_ride_otp"
        case .updateBankDetails: return "/driver_update_bank"
        case .paymentHistory: return "/payment_history_driver"
        case .customerFeedback: return "/customer_feedback_data"
        case .checkAccountStatus: return "/check_account_status"
        case .getDriverLatLng: return "/get_driverlatlng"
        case .getDriverStatus: return "/get_driver_status"
        case .getNearClients: return "/get_nearclient"
        case .driverFeedback: return "/driver_feedback"
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
                "password": password,
                "device_type": "ios"
            ]
            
        case .forgotPassword(let email):
            return [
                "driver_id": email
            ]
            
        case .changePassword(let password):
            return [
                "driver_id": driverId,
                "password": password
            ]
            
        case .updateProfile(
            let driverName,
            let driverPhoto,
            let licensePhoto,
            let vehicleInsurancePhoto,
            let badgePhoto
        ):
            return [
                "driver_id": driverId,
                "driverName": driverName,
                "driver_photo": driverPhoto ?? "",
                "license_photo": licensePhoto ?? "",
                "badge_photo": badgePhoto ?? "",
                "vehicle_insurance_photo": vehicleInsurancePhoto ?? ""
            ]
            
        case .logout:
            return ["driver_id": driverId]
            
        case .getDriverDetails:
            return ["driver_id": driverId]
            
        case .changeStatus(let status):
            return [
                "driver_id": driverId,
                "status": status
            ]
            
        case .updateLocation(let lat, let lng, let bookingId):

            var params: Parameters = [
                "driver_id": driverId,
                "latitude": lat,
                "longitude": lng,
                "date": Date().apiDate,
                "time": Date().apiTime
            ]

            // Android sends `booking_id` only from `RouteDetailsActivity`, i.e.
            // while a trip is running. The idle poll in `MainActivity` omits the
            // key entirely — sending it as "" is a different request, and an
            // empty booking reference is not something the backend expects to
            // file a free driver's position under.
            if !bookingId.isEmpty {
                params["booking_id"] = bookingId
            }

            return params
        case .updateFCMToken(let token):
            return [
                "driver_id": driverId,
                "token": token
            ]
            
        case .lastBooking:
            return [
                "driver_id": driverId
            ]
            
        case .bookingList:
            return ["driver_id": driverId]
            
        case .getBookingData(let bookingId):
            return ["driver_id": driverId,
                "booking_id": bookingId]
            
        case .changeBookingStatus(let bookingId, let status, let cancelMessage):
            var params: Parameters = [
                "booking_id": bookingId,
                "driver_id": driverId,
                "assign_status": status
            ]

            if let cancelMessage, !cancelMessage.isEmpty {
                params["cancel_message"] = cancelMessage
            }
            return params
            
        case .submitFinalFare(
            let bookingId,
            let price,
            let tollCharge,
            let feedback,
            let customerRate
        ):
            // Keys match Android's giveFeedback(): book_id (not booking_id),
            // price, toll_charge, feedback, customer_rate.
            return [
                "book_id": bookingId,
                "price": price,
                "toll_charge": tollCharge,
                "feedback": feedback,
                "customer_rate": customerRate
            ]

        case .sendRideOTP(let bookingId):
            return ["driver_id": driverId,
                    "booking_id": bookingId]
            
        case .verifyRideOTP(let bookingId, let otp):
            return ["driver_id": driverId,
                    "booking_id": bookingId,
                    "otp": otp]
            
        case .updateBankDetails(let parameters):
            var params = parameters
            params["driver_id"] = driverId
            return params
            
        case .paymentHistory:
            return [
                "driver_id": driverId
            ]
            
        case .customerFeedback:
            return [
                "driver_id": driverId
            ]
            
        case .checkAccountStatus:
            return [
                "id": driverId
            ]
            
        case .getDriverLatLng:
            return [
                "driver_id": driverId
            ]
            
        case .getDriverStatus:
            return [
                "driver_id": driverId
            ]
            
        case .getNearClients(let lat, let lng):
            return [
                "lat": lat,
                "long": lng
            ]
            
        case .driverFeedback(let bookingId, let feedback, let rate):
            return [
                "booking_id": bookingId,
                "feedback": feedback,
                "rate": rate
            ]
        }
    }
}
