//
//  DirectionsService.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 06/07/26.
//

import Foundation
import CoreLocation
import GoogleMaps

struct RouteInfo {
    let path: GMSPath      // decoded polyline
    let distanceText: String
    let durationText: String
}

final class DirectionsService {
    static let apiKey = MapAPIKey.directionApiKey
    
    static func fetchRoute(
        origin: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D
    ) async throws -> RouteInfo {
        var components = URLComponents(string: "https://maps.googleapis.com/maps/api/directions/json")!
        components.queryItems = [
            .init(name: "origin", value: "\(origin.latitude),\(origin.longitude)"),
            .init(name: "destination", value: "\(destination.latitude),\(destination.longitude)"),
            .init(name: "mode", value: "driving"),
            .init(name: "key", value: apiKey)
        ]
        
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        
        // 👇 TEMP DEBUG — print raw JSON
        print("Directions raw response:", String(data: data, encoding: .utf8) ?? "no data")
        
        let decoded = try JSONDecoder().decode(DirectionsResponse.self, from: data)
        
        guard let route = decoded.routes.first,
              let leg = route.legs.first,
              let path = GMSPath(fromEncodedPath: route.overview_polyline.points) else {
            throw URLError(.badServerResponse)
        }
        
        return RouteInfo(path: path, distanceText: leg.distance.text, durationText: leg.duration.text)
    }
}
