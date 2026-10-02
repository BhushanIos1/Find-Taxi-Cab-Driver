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

    static let casingWidth: CGFloat = 18
    static let coreWidth: CGFloat = 12
    static let traveledWidth: CGFloat = 12

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
    static let capZ: Int32 = 4
    static let markerZ: Int32 = 5

    /// `GMSPolyline` has no line-cap property at all — every line is drawn
    /// with flat, square-cut ends, which looks like the route was simply
    /// chopped off. A small dot layered the same way as the line itself
    /// (dark casing ring, bright core center) sits over each endpoint and
    /// rounds it off, the way Uber's route line reads as one continuous
    /// rounded shape rather than a rectangle with pins stuck in it.
    static let capDiameter: CGFloat = casingWidth
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

    /// Rounds off the otherwise flat-cut ends of the drawn route — see
    /// `RouteStyle.capDiameter`. Fixed at the route's two endpoints for the
    /// life of the leg; unlike the car marker, these never move.
    private var startCapMarker: GMSMarker?
    private var endCapMarker: GMSMarker?

    /// Built once and reused for both caps — identical image either way, and
    /// cheap to keep around rather than re-rendering on every `drawRoute`.
    private static let capIcon: UIImage = {
        let size = CGSize(width: RouteStyle.capDiameter, height: RouteStyle.capDiameter)
        return UIGraphicsImageRenderer(size: size).image { _ in
            RouteStyle.casingColor.setFill()
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()

            let coreInset = (RouteStyle.capDiameter - RouteStyle.coreWidth) / 2
            RouteStyle.coreColor.setFill()
            UIBezierPath(ovalIn: CGRect(origin: .zero, size: size).insetBy(dx: coreInset, dy: coreInset)).fill()
        }
    }()

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

        startCapMarker?.map = nil
        startCapMarker = nil

        endCapMarker?.map = nil
        endCapMarker = nil

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

        // Directions snaps `waypoint` (the raw pickup/destination coordinate
        // from the booking) onto the nearest road before routing to it — a
        // building is rarely sitting exactly on one. Pinning the marker to
        // that raw coordinate instead of the route's own endpoint left a
        // visible gap between where the polyline actually stopped and where
        // the pin was drawn. The route's decoded path always starts and ends
        // at the exact coordinates Directions routed to, so anchoring the pin
        // there guarantees the line runs right into it, the way Uber's does.
        let pinCoordinate = route.path.count() > 0
            ? route.path.coordinate(at: route.path.count() - 1)
            : waypoint

        waypointMarker?.map = nil
        waypointMarker = makeMarker(at: pinCoordinate, title: waypointTitle, color: waypointColor)

        startCapMarker?.map = nil
        endCapMarker?.map = nil
        if route.path.count() > 0 {
            startCapMarker = makeCapMarker(at: route.path.coordinate(at: 0))
            endCapMarker = makeCapMarker(at: pinCoordinate)
        }

        // The car marker's own last known fix can sit outside the fresh
        // route's bounds for a moment (stale GPS from before this leg was
        // drawn) — folding it in means the very first frame always shows the
        // whole route *and* the car, instead of the camera jumping once the
        // next location update arrives.
        var bounds = GMSCoordinateBounds(path: route.path)
        if let driverCoord = driverMarker?.position {
            bounds = bounds.includingCoordinate(driverCoord)
        }
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

    private func makeCapMarker(at coord: CLLocationCoordinate2D) -> GMSMarker {
        let marker = GMSMarker(position: coord)
        marker.icon = Self.capIcon
        marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        marker.zIndex = RouteStyle.capZ
        marker.isFlat = true
        marker.tracksViewChanges = false // a static dot — no need to redraw it every frame
        marker.map = mapView
        return marker
    }

    // MARK: - Live location → smooth camera + marker animation
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last, let mapView else { return }
        let rawCoord = location.coordinate

        // Uber-style map matching: the raw GPS fix jitters a few meters either
        // side of the road on every tick, which used to show up as the car icon
        // wobbling off the drawn line instead of riding it. Snapping to the
        // nearest point on the route — and using that segment's own heading
        // rather than the GPS course, which is noisy at low speed — keeps the
        // marker locked to the polyline the way Uber's does. Falls back to the
        // raw fix when there's no route yet, or the driver is genuinely off it
        // (wrong turn), rather than magnetically dragging them back onto it.
        let snapped = fullRoutePath.flatMap { projectOntoRoute(rawCoord, path: $0) }
        let coord = snapped?.coordinate ?? rawCoord
        let bearing = snapped?.bearing ?? (location.course >= 0 ? location.course : mapView.camera.bearing)

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

        updateRemainingRoute(from: coord, atSegment: snapped?.segmentIndex)
    }

    /// Finds the closest point to `coordinate` lying *on* the route itself —
    /// not just the closest existing vertex — along with the heading of the
    /// segment it landed on and that segment's start index. A Directions
    /// polyline's vertices can be tens of meters apart on straight roads, so
    /// snapping only to vertices would make the marker visibly hop between
    /// them; this lands it anywhere along the line in between.
    private func projectOntoRoute(
        _ coordinate: CLLocationCoordinate2D,
        path: GMSPath
    ) -> (coordinate: CLLocationCoordinate2D, bearing: CLLocationDirection, segmentIndex: UInt)? {

        guard path.count() > 1 else { return nil }

        var best: (point: CLLocationCoordinate2D, index: UInt, distance: CLLocationDistance)?

        for i in 0..<(path.count() - 1) {
            let a = path.coordinate(at: i)
            let b = path.coordinate(at: i + 1)

            let projected = closestPoint(on: a, b, to: coordinate)
            let distance = GMSGeometryDistance(coordinate, projected)

            if best == nil || distance < best!.distance {
                best = (projected, i, distance)
            }
        }

        guard let best else { return nil }

        // GPS can drift tens of meters off the road in a city with tall
        // buildings. Beyond this it's no longer "noise to smooth over" — the
        // driver may genuinely have left the route, and showing their real
        // position beats magnetically pinning them to a route they're not on.
        guard best.distance < 40 else { return nil }

        let a = path.coordinate(at: best.index)
        let b = path.coordinate(at: best.index + 1)
        let bearing = GMSGeometryHeading(a, b)

        return (best.point, bearing, best.index)
    }

    /// Closest point on segment `a`→`b` to point `p`, via a flat-plane
    /// projection (longitude scaled by `cos(latitude)` to correct for its
    /// shrinking real-world distance away from the equator). Accurate enough
    /// at the length of a single Directions-polyline segment, and far cheaper
    /// than true great-circle projection run on every GPS tick.
    private func closestPoint(
        on a: CLLocationCoordinate2D,
        _ b: CLLocationCoordinate2D,
        to p: CLLocationCoordinate2D
    ) -> CLLocationCoordinate2D {

        let cosLat = cos(p.latitude * .pi / 180)

        let ax = a.longitude * cosLat, ay = a.latitude
        let bx = b.longitude * cosLat, by = b.latitude
        let px = p.longitude * cosLat, py = p.latitude

        let dx = bx - ax, dy = by - ay
        let lengthSquared = dx * dx + dy * dy

        guard lengthSquared > 0 else { return a }

        let t = max(0, min(1, ((px - ax) * dx + (py - ay) * dy) / lengthSquared))

        return CLLocationCoordinate2D(latitude: ay + t * dy, longitude: (ax + t * dx) / cosLat)
    }

    /// Splits the route at the driver's current point: everything behind them
    /// becomes the muted "traveled" line, everything ahead stays bright.
    /// Measured against `fullRoutePath` rather than the drawn polylines, since
    /// those get trimmed each tick and would otherwise drift.
    ///
    /// The split is seamed at `coord` itself — not the nearest vertex — so the
    /// traveled/remaining boundary always sits exactly under the marker rather
    /// than snapping forward or back by up to one polyline segment, which is
    /// what used to make the line look disjointed where the car sat.
    private func updateRemainingRoute(from coord: CLLocationCoordinate2D, atSegment segmentIndex: UInt?) {

        guard let path = fullRoutePath, path.count() > 1 else { return }

        let index = segmentIndex ?? nearestVertexIndex(to: coord, on: path)

        let traveled = GMSMutablePath()
        for i in 0...index {
            traveled.add(path.coordinate(at: i))
        }
        traveled.add(coord)

        let remaining = GMSMutablePath()
        remaining.add(coord)
        for i in (index + 1)..<path.count() {
            remaining.add(path.coordinate(at: i))
        }

        traveledPolyline?.path = traveled

        // Casing and core share the same remaining path so the border stays
        // registered to the bright stroke on every frame.
        routeCasingPolyline?.path = remaining
        routePolyline?.path = remaining
    }

    /// Fallback for `updateRemainingRoute` when `projectOntoRoute` found no
    /// usable segment (driver off-route) — nearest existing vertex, same as
    /// this method's original, coarser behavior.
    private func nearestVertexIndex(to coord: CLLocationCoordinate2D, on path: GMSPath) -> UInt {

        var nearestIndex: UInt = 0
        var minDist = CLLocationDistance.greatestFiniteMagnitude

        for i in 0..<path.count() {
            let dist = GMSGeometryDistance(coord, path.coordinate(at: i))
            if dist < minDist {
                minDist = dist
                nearestIndex = i
            }
        }

        return nearestIndex
    }
}
