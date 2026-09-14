//
//  DriverNavigationMapView.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 07/07/26.
//

import GoogleMaps
import SwiftUI

struct DriverNavigationMapView: UIViewRepresentable {

    @ObservedObject var viewModel: NavigationViewModel

    func makeUIView(context: Context) -> GMSMapView {
        let options = GMSMapViewOptions()
        let mapView = GMSMapView(options: options)
        mapView.isMyLocationEnabled = false // we'll draw our own driver marker
        viewModel.mapView = mapView
        return mapView
    }

    func updateUIView(_ uiView: GMSMapView, context: Context) {}
}

/// Which leg of the trip the drawn route currently represents — Uber shows one
/// waypoint at a time: the pickup pin while en route to collect the rider, then
/// the destination pin once they're on board. Never both at once.
enum RideLeg {
    case toPickup
    case toDestination
}

/// Uber-style route styling. The widths matter as much as the colours: a thin
/// line looks like a map annotation, a thick cased line reads as "this is your
/// route". Casing is always the widest so it shows as a border on both sides.
private enum RouteStyle {

    static let casingWidth: CGFloat = 13
    static let coreWidth: CGFloat = 8
    static let traveledWidth: CGFloat = 8

    /// Near-black with a blue cast — dark enough to separate the route from any
    /// tile underneath without looking like a plain black scribble.
    static let casingColor = UIColor(red: 0.05, green: 0.09, blue: 0.17, alpha: 0.95)

    /// The bright "live route" blue.
    static let coreColor = UIColor(red: 0.16, green: 0.55, blue: 1.00, alpha: 1.00)

    /// Already-driven portion: still visible for context, clearly de-emphasised.
    static let traveledColor = UIColor(white: 0.58, alpha: 0.50)

    /// Draw order — the driver's car marker sits above all of them.
    static let traveledZ: Int32 = 1
    static let casingZ: Int32 = 2
    static let coreZ: Int32 = 3
    static let markerZ: Int32 = 5
}

final class NavigationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {

    var mapView: GMSMapView?
    private let locationManager = CLLocationManager()

    /// The route is drawn as three stacked strokes, the way Uber and Google Maps
    /// both do it — a single flat line reads as a scribble over busy map tiles.
    ///   • `traveledPolyline` — muted grey, the part already driven
    ///   • `routeCasingPolyline` — dark, widest, the outline that lifts the route
    ///     off the map and keeps it legible over roads, parks and satellite tiles
    ///   • `routePolyline` — the bright core, drawn on top
    private var traveledPolyline: GMSPolyline?
    private var routeCasingPolyline: GMSPolyline?
    private var routePolyline: GMSPolyline?

    /// Kept so progress can be recomputed against the original route on every GPS
    /// tick — the drawn polylines get trimmed, so they can't be their own source.
    private var fullRoutePath: GMSPath?

    private var driverMarker: GMSMarker?
    private var waypointMarker: GMSMarker?

    private var pickupCoordinate: CLLocationCoordinate2D?
    private var destinationCoordinate: CLLocationCoordinate2D?

    @Published private(set) var currentLeg: RideLeg = .toPickup
    @Published var distanceRemaining: String = ""
    @Published var etaText: String = ""

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.activityType = .automotiveNavigation
        locationManager.distanceFilter = 5 // meters
    }

    /// Starts leg 1: the driver's current position → the pickup point. This is
    /// what the driver sees the instant a booking is accepted.
    /// - Parameter leg: which leg to draw. Defaults to `.toPickup` for a freshly
    ///   accepted booking. A trip restored after the app was killed passes the leg
    ///   it was already on, so only that one route is fetched — starting at
    ///   `.toPickup` and then advancing would fire two overlapping Directions
    ///   requests and whichever returned last would win the map.
    func startRide(
        from currentLocation: CLLocationCoordinate2D,
        pickup: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        resuming leg: RideLeg = .toPickup
    ) {
        pickupCoordinate = pickup
        destinationCoordinate = destination
        currentLeg = leg

        // `GoogleMapView` (the map HomeScreen actually embeds) turns on Google's own
        // "My Location" blue-dot layer for the idle map. That layer keeps its own
        // camera/marker independent of anything below, so once real navigation
        // starts it's exactly what makes the map look like it "snaps back" to the
        // driver's raw current position instead of holding the tilted, bearing-
        // following nav camera. Turn it off for the duration of the ride — `stopRide()`
        // turns it back on for the idle map.
        mapView?.isMyLocationEnabled = false
        mapView?.settings.myLocationButton = false

        switch leg {

        case .toPickup:
            drawLeg(from: currentLocation, to: pickup, waypointTitle: "Pickup", waypointColor: .systemGreen)

        case .toDestination:
            // Resuming mid-trip: route from where the driver actually is now,
            // not from the pickup point they already left.
            drawLeg(from: currentLocation, to: destination, waypointTitle: "Destination", waypointColor: .systemRed)
        }

        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }

    /// Starts leg 2: pickup → destination. Call this once `ON BOARD` succeeds —
    /// the rider is physically in the car, so the pickup pin is retired and the
    /// destination pin takes over.
    func beginTripToDestination() {

        guard let pickup = pickupCoordinate, let destination = destinationCoordinate else {
            return
        }

        currentLeg = .toDestination

        drawLeg(from: pickup, to: destination, waypointTitle: "Destination", waypointColor: .systemRed)
    }

    /// Clears the drawn route and driver marker — called when a trip is cancelled
    /// or completed so a stale route doesn't linger on the map for the next booking.
    func stopRide() {
        clearRouteOverlays()
        fullRoutePath = nil

        driverMarker?.map = nil
        driverMarker = nil

        waypointMarker?.map = nil
        waypointMarker = nil

        pickupCoordinate = nil
        destinationCoordinate = nil
        currentLeg = .toPickup

        distanceRemaining = ""
        etaText = ""

        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()

        // Hand the camera back to the idle map's own "My Location" behavior.
        mapView?.isMyLocationEnabled = true
        mapView?.settings.myLocationButton = true
    }

    private func drawLeg(
        from origin: CLLocationCoordinate2D,
        to waypoint: CLLocationCoordinate2D,
        waypointTitle: String,
        waypointColor: UIColor
    ) {
        Task {
            do {
                let route = try await DirectionsService.fetchRoute(origin: origin, destination: waypoint)
                await MainActor.run {
                    drawRoute(route, waypoint: waypoint, waypointTitle: waypointTitle, waypointColor: waypointColor)
                    distanceRemaining = route.distanceText
                    etaText = route.durationText
                }
            } catch {
                print("Route fetch failed: \(error)")
            }
        }
    }

    private func drawRoute(
        _ route: RouteInfo,
        waypoint: CLLocationCoordinate2D,
        waypointTitle: String,
        waypointColor: UIColor
    ) {
        guard let mapView else { return }

        clearRouteOverlays()

        fullRoutePath = route.path

        // Bottom layer: the driven-so-far line. Starts empty and fills in as the
        // driver progresses, so the route visibly "burns down" behind the car
        // instead of just vanishing.
        let traveled = GMSPolyline()
        traveled.strokeWidth = RouteStyle.traveledWidth
        traveled.strokeColor = RouteStyle.traveledColor
        traveled.geodesic = true
        traveled.zIndex = RouteStyle.traveledZ
        traveled.map = mapView
        traveledPolyline = traveled

        let casing = GMSPolyline(path: route.path)
        casing.strokeWidth = RouteStyle.casingWidth
        casing.strokeColor = RouteStyle.casingColor
        casing.geodesic = true
        casing.zIndex = RouteStyle.casingZ
        casing.map = mapView
        routeCasingPolyline = casing

        let core = GMSPolyline(path: route.path)
        core.strokeWidth = RouteStyle.coreWidth
        core.strokeColor = RouteStyle.coreColor
        core.geodesic = true
        core.zIndex = RouteStyle.coreZ
        core.isTappable = true
        core.map = mapView
        routePolyline = core

        waypointMarker?.map = nil
        waypointMarker = makeMarker(at: waypoint, title: waypointTitle, color: waypointColor)

        let bounds = GMSCoordinateBounds(path: route.path)
        mapView.animate(with: .fit(bounds, withPadding: 60))
    }

    private func clearRouteOverlays() {
        traveledPolyline?.map = nil
        traveledPolyline = nil

        routeCasingPolyline?.map = nil
        routeCasingPolyline = nil

        routePolyline?.map = nil
        routePolyline = nil
    }

    private func makeMarker(at coord: CLLocationCoordinate2D, title: String, color: UIColor) -> GMSMarker {
        let marker = GMSMarker(position: coord)
        marker.title = title
        marker.icon = GMSMarker.markerImage(with: color)
        marker.map = mapView
        return marker
    }

    // MARK: - Live location → smooth camera + marker animation
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, let mapView else { return }
        let coord = location.coordinate
        let bearing = location.course >= 0 ? location.course : mapView.camera.bearing

        if driverMarker == nil {
            let marker = GMSMarker(position: coord)
            marker.icon = UIImage(named: "car_icon") // your car asset
            marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
            marker.rotation = bearing
            marker.zIndex = RouteStyle.markerZ // above all three route strokes
            marker.isFlat = true // rotates with the map instead of standing upright
            marker.map = mapView
            driverMarker = marker
        }

        CATransaction.begin()
        CATransaction.setAnimationDuration(1.0) // match distanceFilter/update cadence
        driverMarker?.position = coord
        driverMarker?.rotation = bearing
        CATransaction.commit()

        let camera = GMSCameraPosition(
            target: coord,
            zoom: 17.5,
            bearing: bearing,
            viewingAngle: 45 // tilt, gives that navigation "3D" feel
        )
        mapView.animate(to: camera)

        updateRemainingRoute(from: coord)
    }

    /// Splits the route at the driver's nearest point: everything behind them
    /// becomes the muted "traveled" line, everything ahead stays bright. Measured
    /// against `fullRoutePath` rather than the drawn polylines, since those get
    /// trimmed each tick and would otherwise drift.
    private func updateRemainingRoute(from coord: CLLocationCoordinate2D) {

        guard let path = fullRoutePath, path.count() > 1 else { return }

        var nearestIndex: UInt = 0
        var minDist = CLLocationDistance.greatestFiniteMagnitude

        for i in 0..<path.count() {
            let point = path.coordinate(at: i)
            let dist = GMSGeometryDistance(coord, point)
            if dist < minDist {
                minDist = dist
                nearestIndex = i
            }
        }

        let traveled = GMSMutablePath()
        for i in 0...nearestIndex {
            traveled.add(path.coordinate(at: i))
        }

        let remaining = GMSMutablePath()
        for i in nearestIndex..<path.count() {
            remaining.add(path.coordinate(at: i))
        }

        traveledPolyline?.path = traveled

        // Casing and core share the same remaining path so the border stays
        // registered to the bright stroke on every frame.
        routeCasingPolyline?.path = remaining
        routePolyline?.path = remaining
    }
}
