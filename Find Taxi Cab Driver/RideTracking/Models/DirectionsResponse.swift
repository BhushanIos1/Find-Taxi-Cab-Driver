//
//  DirectionsResponse.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 06/07/26.
//

struct DirectionsResponse: Decodable {
    
    let routes: [Route]
    struct Route: Decodable {
        let overview_polyline: Polyline
        let legs: [Leg]
    }
    struct Polyline: Decodable { let points: String }
    struct Leg: Decodable {
        let distance: TextValue
        let duration: TextValue
    }
    struct TextValue: Decodable { let text: String }
}
