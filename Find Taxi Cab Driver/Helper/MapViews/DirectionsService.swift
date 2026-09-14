//
//  DirectionsService.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 06/07/26.
//

import Foundation
import CoreLocation

final class DirectionsService {

    static let shared = DirectionsService()

    private init() {}

    // Replace with your Google Maps API Key

    func fetchRoute(
        from source: CLLocationCoordinate2D,
        to destination: CLLocationCoordinate2D
    ) async throws -> String {

        let urlString =
        "https://maps.googleapis.com/maps/api/directions/json?" +
        "origin=\(source.latitude),\(source.longitude)" +
        "&destination=\(destination.latitude),\(destination.longitude)" +
        "&mode=driving" +
        "&key=\(MapAPIKey.apiKey)"

        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let directions = try JSONDecoder().decode(
            DirectionsResponse.self,
            from: data
        )

        guard let polyline = directions.routes.first?.overviewPolyline.points else {
            throw NSError(
                domain: "DirectionsService",
                code: -1,
                userInfo: [
                    NSLocalizedDescriptionKey: "No route found."
                ]
            )
        }

        return polyline
    }
}
