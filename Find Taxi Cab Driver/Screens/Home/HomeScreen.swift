//
//  HomeScreen.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 04/03/26.
//

import SwiftUI
import CoreLocation

/// The driver's progress through an accepted trip. Mirrors the three
/// mutually-exclusive button containers in Android's `RouteDetailsActivity`,
/// each advanced by the `assign_status` value the previous stage posted.
enum TripStage {
    /// Just accepted. `PICKUP USER` posts `pickcustomer` — this is also the
    /// status that pushes `book_pickcustomer` to the rider, which is what moves
    /// the rider app off its "driver accepted" waiting state onto live tracking.
    case pickupUser

    /// En route to collect the rider. `ON BOARD` posts `onboard`.
    case onBoard

    /// Rider is in the car. `COMPLETED` posts `complete`.
    case markCompleted
}

extension TripStage {

    /// Rebuilds the stage from a booking's `assign_status` when restoring a trip
    /// after the app was killed. Android gates resume on exactly these three
    /// values in `BookingPage.continue_booking()` — anything else ("complete",
    /// "cancel", "reject") is a finished or dead booking and must not be restored,
    /// which is why this is failable rather than defaulting to a stage.
    init?(assignStatus: String) {

        switch assignStatus.lowercased() {

        case "accept":
            self = .pickupUser

        case "pickcustomer":
            self = .onBoard

        case "onboard":
            self = .markCompleted

        default:
            return nil
        }
    }
}

struct HomeScreen: View {

    @EnvironmentObject
    private var router: AppRouter

    @Environment(\.colorScheme) var colorScheme

    @EnvironmentObject
    private var toastManager: ToastManager

    @Environment(\.scenePhase) private var scenePhase

    @State private var presentSideMenu = false

    @StateObject
    private var locationService = LocationService()

    @State private var showShareSheet = false
    @State private var showLogoutAlert = false

    /// Purely the nav-bar switch's own state. It is deliberately NOT wired to the
    /// booking flow — a toggle up there must never be able to silently skip a ride
    /// offer, which is exactly what happened while it drove auto-accept.
    @State private var isOnline = true

    @State private var showRidePopup = false

    /// Whether the offer currently in `showRidePopup` came from `admin_booking`
    /// rather than the normal driver-matching push — set right before each
    /// fetch, so it's already correct by the time `incomingOffer` lands and
    /// opens the popup.
    @State private var isAdminBookingOffer = false

    /// Whether the *active* trip (post-accept) came from `admin_booking` —
    /// hides CHAT, since an admin-assigned booking never had a customer
    /// thread opened against it the way a driver-matched one does.
    @State private var activeBookingIsAdmin = false

    /// `BookingData` (from `/get_bookdata`, `/booking` or `driver_last_book`)
    /// carries nothing that says "this came from admin" — that's only known
    /// at the moment the push itself arrives. Persisting the accepted admin
    /// booking's id is what lets `restoreTrip(from:)` still hide CHAT after
    /// the app is killed and relaunched mid-trip.
    @AppStorage("activeAdminBookingId") private var persistedAdminBookingId = ""

    @StateObject
    private var homeViewModel = HomeViewModel()

    @StateObject
    private var viewModel = RegisterViewModel()

    @StateObject
    private var bookingViewModel = BookingViewModel()

    @State private var showCancelPopup = false

    /// The server's `change_book_status` failure message for the CANCEL flow
    /// specifically, shown inline in `CancelPopupView` rather than only as a
    /// toast — the popup stays open on failure so this is still visible, and
    /// SUBMIT doubles as retry.
    @State private var cancelErrorMessage: String?

    @StateObject
    private var navigationViewModel = NavigationViewModel()

    // 7s, matching Android's `MainActivity`/`RouteDetailsActivity` (`delay = 7000`)
    // posting loop against `api/driver_location`.
    @State private var locationTimer = Timer.publish(every: 7, on: .main, in: .common).autoconnect()

    @State private var showBlockedAlert = false

    /// Presented after COMPLETED so the driver can submit the trip's final price
    /// via `/miles_cal` — the step that lets the rider's `get_fair`/payment happen.
    @State private var showTripFarePopup = false

    @State private var showOTPView = false

    /// The booking currently in progress (accepted, on board, etc.) — threaded
    /// into every trip-scoped call (ON BOARD, CANCEL, SEND SMS, OTP verify)
    /// instead of the empty placeholder those used to send.
    @State private var activeBookingId = ""

    /// Marks a `changeBookingStatus` call fired directly by this screen (PICKUP USER,
    /// ON BOARD, COMPLETED, or the CANCEL flow) so `applyBookingStateHandler`'s success
    /// branch knows what follow-up to run. Accept/reject from the popup doesn't use
    /// this — it reports back through `onAccepted` instead, since it owns its own view model.
    @State private var pendingHomeAction: BookingAction?

    /// Which leg of the accepted trip the driver is on. Reset to `.pickupUser`
    /// every time a booking is accepted; advanced only by a confirmed
    /// `change_book_status` response, never optimistically.
    @State private var tripStage: TripStage = .pickupUser

    /// The rider's number for this trip, snapshotted at accept time — the same way
    /// Android hands `cus_mob` to `RouteDetailsActivity` as the `cus_mobile` intent
    /// extra. Deliberately not read live off `bookingViewModel.incomingOffer`,
    /// which gets cleared and refilled by any later offer that comes in.
    @State private var activeCustomerPhone = ""

    /// Shown at the top of the TRIP FARE dialog so the driver can see which job
    /// they are pricing.
    @State private var activePickupAddress = ""
    @State private var activeDropAddress = ""

    /// The last `assign_status` the **server** confirmed for this trip — the value
    /// `tripStage` is derived from, kept rather than discarded. Set from
    /// `/driver_last_book` on relaunch and re-set after every successful
    /// `change_book_status`, so "what stage is this driver on" always has a
    /// server-backed answer instead of only living in the button UI.
    @State private var activeBookingStatus = ""

    // Split into pieces the type-checker can solve independently — a single chain
    // this long (map, nav bar, lifecycle, push routing, booking state, alerts,
    // sheets, overlays) blows past Swift's per-expression time budget.
    var body: some View {
        let withLifecycle = applyLifecycleHandlers(to: mapContent)
        let withPush = applyPushNotificationHandlers(to: withLifecycle)
        let withBookingState = applyBookingStateHandler(to: withPush)
        let withAlerts = applyAlerts(to: withBookingState)
        return applySheetsAndOverlays(to: withAlerts)
    }

    private var mapContent: some View {
        ZStack {

            GoogleMapView { mapView in
                navigationViewModel.mapView = mapView
            }
            .ignoresSafeArea()

            VStack {
                Spacer()
                bottomSection
            }
        }
        .appNavigationBar(
            title: "Home",
            leading: .menu, toggleBinding: $isOnline
        ) {
            withAnimation(.easeInOut) {
                presentSideMenu.toggle()
            }
        }
    }
}

private extension HomeScreen {

    /// Consumes `chatToOpen` if it's set — from either the live tap arriving
    /// while this screen is already up, or one that landed before this screen
    /// had mounted at all (a cold launch straight from a tapped notification,
    /// where `@Published` has nothing to replay to a subscriber that joins
    /// late). Idempotent: safe to call from both `.onAppear` and `.onReceive`.
    func openPendingChatIfNeeded() {

        guard let bookingId = NotificationManager.shared.chatToOpen,
              !bookingId.isEmpty else {
            return
        }

        NotificationManager.shared.chatToOpen = nil

        router.push(.chat(bookingId: bookingId))
    }
}

private extension HomeScreen {

    @ViewBuilder
    func applyLifecycleHandlers(to content: some View) -> some View {
        content
            .onAppear {
                locationService.startTracking()
                homeViewModel.syncStatusOnAppear()
                homeViewModel.checkBlockedStatus()

                // Killed mid-trip? Pick it back up.
                bookingViewModel.restoreActiveBooking()

                openPendingChatIfNeeded()

                // Every time this account's Home appears — cold launch or
                // resuming a session — this device re-asserts its token as the
                // one the server should push to. A device that logged in once
                // and is never reopened again simply never runs this a second
                // time, so it can't silently steal push back from whichever
                // device the driver is actually using; the one they're holding
                // right now always wins.
                FCMTokenManager.shared.registerWithServerIfLoggedIn()
            }
            .onChange(of: scenePhase) { phase in

                // Re-ask the server on every return to foreground, not just cold
                // launch. The driver may have advanced the trip on another device,
                // or dispatch may have moved it on, and `restoreTrip` re-stages
                // when the returned status differs from the one being shown.
                guard phase == .active else { return }

                bookingViewModel.restoreActiveBooking()

                // Also on every return to foreground, not just the first mount —
                // `.onAppear` alone only fires once for the life of this screen
                // in the navigation stack, so leaving the app backgrounded for a
                // long stretch and coming back would otherwise go untouched.
                FCMTokenManager.shared.registerWithServerIfLoggedIn()
            }
            .onReceive(locationTimer) { _ in

                guard let location = locationService.currentLocation else {
                    return
                }

                homeViewModel.updateLocation(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude,
                    bookingId: activeBookingId
                )
            }
    }

    /// Everything driven by an inbound push: the local broadcast from
    /// `NotificationManager`, the booking-fetch it triggers, and the blocked flag
    /// the one-shot status check can also set.
    @ViewBuilder
    func applyPushNotificationHandlers(to content: some View) -> some View {
        content
            .onReceive(NotificationManager.shared.$pendingNotification) { payload in

                guard let payload else { return }

                handleIncomingNotification(payload)

                NotificationManager.shared.pendingNotification = nil
            }
            // Chat opened from a tapped notification. Handled here because Home
            // is the one screen alive for as long as the driver is logged in,
            // whatever they have navigated into since.
            .onReceive(NotificationManager.shared.$chatToOpen) { _ in
                openPendingChatIfNeeded()
            }
            .onChange(of: bookingViewModel.incomingOffer) { details in

                guard details != nil else { return }

                // Unconditional: the booking details landing is the one and only
                // trigger for the offer popup. Nothing gates this.
                withAnimation(.easeInOut) {
                    showRidePopup = true
                }
            }
            .onChange(of: homeViewModel.isBlocked) { isBlocked in

                guard isBlocked else { return }

                showBlockedAlert = true
            }
            .onChange(of: bookingViewModel.restorableBooking) { booking in

                guard let booking else { return }

                restoreTrip(from: booking)

                bookingViewModel.restorableBooking = nil
            }
    }

    @ViewBuilder
    func applyBookingStateHandler(to content: some View) -> some View {
        content
            .onChange(of: bookingViewModel.bookingState) { state in

                guard let state else { return }

                switch state {

                case .failure(let message):

                    // `change_book_status` documents a real error contract —
                    // {"result":"failed","message":"Booking Can Not Be Proceeded,
                    // Something Went Wrong"}. That message was being swallowed
                    // entirely: the driver tapped a button, the server refused,
                    // and nothing at all appeared on screen.
                    //
                    // OTP results no longer arrive here at all — they have their
                    // own `otpState`, which the sheet owns.
                    toastManager.showToast(
                        type: .error,
                        title: "Failed",
                        subtitle: message
                    )

                    // CANCEL keeps its popup open on failure — the same message
                    // shown inline there, with SUBMIT itself now acting as retry
                    // rather than forcing the driver to reopen CANCEL and retype
                    // the reason.
                    if pendingHomeAction == .cancel {
                        cancelErrorMessage = message
                    }

                case .success(let message):

                    // Was showing a red "Failed" toast on success — so a successful
                    // PICKUP USER / ON BOARD / COMPLETED told the driver it had failed.
                    toastManager.showToast(
                        type: .success,
                        title: "Success",
                        subtitle: message
                    )

                    // Final fare accepted — only now is the trip actually finished.
                    if bookingViewModel.lastBookingAction == .submitFare {
                        showTripFarePopup = false
                        clearActiveBooking()
                    }

                    switch pendingHomeAction {

                    case .pickCustomer:
                        // Android: changeStatus("pickcustomer", "pickup", …) hides
                        // the pickup button and reveals ON BOARD / CANCEL. The route
                        // stays current → pickup; the driver is on their way to collect.
                        activeBookingStatus = BookingAction.pickCustomer.rawValue
                        withAnimation { tripStage = .onBoard }

                    case .onboard:
                        // Rider is in the car now — switch the drawn route from
                        // "current location → pickup" to "pickup → destination".
                        activeBookingStatus = BookingAction.onboard.rawValue
                        withAnimation { tripStage = .markCompleted }
                        navigationViewModel.beginTripToDestination()

                    case .complete:
                        // Don't tear the trip down yet — Android goes straight from
                        // COMPLETED into the fare/feedback dialog, and `/miles_cal`
                        // still needs this booking id. `clearActiveBooking()` runs
                        // once the fare is submitted (or explicitly skipped).
                        activeBookingStatus = BookingAction.complete.rawValue
                        showTripFarePopup = true

                    case .cancel:
                        showCancelPopup = false
                        cancelErrorMessage = nil
                        clearActiveBooking()

                    default:
                        break
                    }
                }

                pendingHomeAction = nil
                bookingViewModel.bookingState = nil
            }
    }

    @ViewBuilder
    func applyAlerts(to content: some View) -> some View {
        content
            .alert("Logout",
                   isPresented: $showLogoutAlert) {

                Button("NO", role: .cancel) { }

                Button("YES", role: .destructive) {
                    viewModel.logOut(id: "\(AuthManager.shared.driverId)", router: router)

                    router.push(.landingPage)
                }
            } message: {
                Text("Are you sure you want to log out?")
            }
            .alert("Account Blocked",
                   isPresented: $showBlockedAlert) {

                Button("OK", role: .cancel) { }
            } message: {
                Text("Your account has been blocked by the admin. You won't receive new bookings until it's reinstated.")
            }
    }

    @ViewBuilder
    func applySheetsAndOverlays(to content: some View) -> some View {
        content
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [
                    "Check out this amazing Taxi App 🚖",
                    ""
                ])
            }
            .overlay(alignment: .leading) {

                SideMenu(
                    isShowing: $presentSideMenu,
                    content: AnyView(
                        SideMenuView(
                            presentSideMenu: $presentSideMenu
                        ) { selectedRow in
                            handleMenuNavigation(selectedRow)
                        }
                    )
                )
            }
            .rideRequestPopup(
                isPresented: $showRidePopup,
                bookingId: bookingViewModel.incomingOffer?.bookingId ?? "",
                pickup: bookingViewModel.incomingOffer?.pickupAddress ?? "",
                drop: bookingViewModel.incomingOffer?.dropAddress ?? "",
                needs: bookingViewModel.incomingOffer?.specialNeed ?? "None",
                isAdminBooking: isAdminBookingOffer
            ) {
                handleBookingAccepted()
            }
            // Was previously bound to `showRidePopup` (the ride-offer popup's own
            // flag) with a submit handler that only printed — CANCEL never actually
            // reached the server. Now bound to its own `showCancelPopup` flag and
            // wired to the real cancel call.
            .inputPopup(
                isPresented: $showCancelPopup,
                title: "Reason For Cancellation :",
                placeholder: "Type here...",
                buttonTitle: "SUBMIT",
                isSubmitting: bookingViewModel.isLoading && pendingHomeAction == .cancel,
                errorMessage: cancelErrorMessage
            ) { reason in

                guard !bookingViewModel.isLoading else { return }

                cancelErrorMessage = nil
                pendingHomeAction = .cancel

                bookingViewModel.changeBookingStatus(
                    bookingId: activeBookingId,
                    action: .cancel,
                    cancelMessage: reason
                )
            }
            .tripFarePopup(
                isPresented: $showTripFarePopup,
                pickupLocation: activePickupAddress,
                dropLocation: activeDropAddress,
                isSubmitting: bookingViewModel.isLoading,
                onSubmit: { price, tollCharge, comment, rating in

                    bookingViewModel.submitFinalFare(
                        bookingId: activeBookingId,
                        price: price,
                        tollCharge: tollCharge,
                        feedback: comment,
                        // Android sends a RatingBar float — `String.valueOf(
                        // ratingBar.getRating())` gives "5.0", not "5". Matching
                        // the format the backend has actually been receiving.
                        customerRate: String(format: "%.1f", Double(rating))
                    )
                },
                onCancel: {
                    // The trip stays open — `/miles_cal` has not run, so there is
                    // still no final price. The driver lands back on MAKE
                    // COMPLETED and can price it when ready.
                    withAnimation { showTripFarePopup = false }
                }
            )
            .sheet(isPresented: $showOTPView) {

                OTPVerificationSheet(
                    bookingViewModel: bookingViewModel,
                    bookingId: activeBookingId
                ) {
                    startTripAfterOTP()
                }
                .environmentObject(toastManager)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                // Closing mid-request would leave the driver unsure whether the
                // code went through.
                .interactiveDismissDisabled(bookingViewModel.isOTPLoading)
            }
            .overlay(
                GlobalToastView()
                    .environmentObject(toastManager)
            )
    }
}

private extension HomeScreen {

    @ViewBuilder
    var bottomSection: some View {

        if activeBookingId.isEmpty {

            DriverStatusToggle(status: $homeViewModel.driverStatus) {
                homeViewModel.changeStatus()
            }
            .frame(width: 260)

        } else {

            VStack(spacing: 8) {

                primaryActionRow

                // Once the customer is on board, the only thing left to do is
                // finish the trip. CHAT exists to reach the customer before
                // pickup and MAKE CALL to find them at the kerb — both are
                // spent by this point, so the row goes away rather than sitting
                // there as something to tap by mistake mid-journey.
                if tripStage != .markCompleted {

                    HStack(spacing: 8) {

                        // In-app chat against this booking, replacing the SMS
                        // composer: it needs no phone number, keeps the thread
                        // attached to the trip, and the customer sees it inside
                        // their own app. Hidden for an admin-assigned booking —
                        // there's no customer-side thread opened against one.
                        if !activeBookingIsAdmin {

                            ActionButtonView(
                                title: "CHAT",
                                backgroundColor: AppColors.primaryYellow
                            ) {
                                openChat()
                            }
                        }

                        ActionButtonView(
                            title: "MAKE CALL",
                            backgroundColor: AppColors.appBlueColor
                        ) {
                            callCustomer()
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }

    /// One stage visible at a time, mirroring `RouteDetailsActivity`'s three
    /// mutually-exclusive containers (`ll_pickupuser` → `ll_onboard_cancel` →
    /// `ll_onboard_markcompleted`), each advanced by the `assign_status` its
    /// button posts to `change_book_status`.
    @ViewBuilder
    var primaryActionRow: some View {

        switch tripStage {

        case .pickupUser:

            ActionButtonView(
                title: "PICKUP USER",
                backgroundColor: AppColors.greenAppColor
            ) {

                guard !bookingViewModel.isLoading else { return }

                pendingHomeAction = .pickCustomer

                bookingViewModel.changeBookingStatus(
                    bookingId: activeBookingId,
                    action: .pickCustomer
                )
            }

        case .onBoard:

            HStack(spacing: 8) {

                // The trip no longer starts on this tap. It sends the code and
                // opens the OTP gate; `onboard` is posted only after the server
                // accepts what the driver types in — the standard ride-hailing
                // handshake, and the whole point of `verify_ride_otp`. Skipped
                // entirely for an admin-assigned booking: admin created it
                // directly, so there's no customer-side code to hand over —
                // `send_ride_otp`/`verify_ride_otp` never run for one.
                ActionButtonView(
                    title: "ON BOARD",
                    backgroundColor: AppColors.greenAppColor
                ) {

                    guard !bookingViewModel.isLoading else { return }

                    if activeBookingIsAdmin {
                        startTripWithoutOTP()
                    } else {
                        beginOTPVerification()
                    }
                }

                ActionButtonView(
                    title: "CANCEL",
                    backgroundColor: .red
                ) {

                    cancelErrorMessage = nil

                    withAnimation {
                        showCancelPopup = true
                    }
                }
            }

        case .markCompleted:

            // Red, and alone on screen — the one remaining action, and a
            // deliberately weighty one: it ends the trip and opens the fare.
            ActionButtonView(
                title: "MAKE COMPLETED",
                backgroundColor: .red
            ) {

                guard !bookingViewModel.isLoading else { return }

                pendingHomeAction = .complete

                bookingViewModel.changeBookingStatus(
                    bookingId: activeBookingId,
                    action: .complete
                )
            }
        }
    }
}

private extension HomeScreen {

    /// Routes a decoded push to a screen action — the counterpart of Android's
    /// `MainActivity.changeFlow(status)` switch and `RouteDetailsActivity`'s
    /// `booking_cancel` handling, both driven by the same `notification_status` field.
    func handleIncomingNotification(_ payload: NotificationPayload) {

        switch NotificationManager.shared.driverAction(for: payload) {

        case .newBooking:

            // Android: MainActivity.getBookData(driver_id) → api/get_bookdata → showJobDialog()
            guard let bookingId = payload.bookingId else {
                print("⚠️ 'booking' push arrived with no booking_id — cannot fetch the offer. Raw status was: \(payload.status)")
                return
            }

            print("📥 New booking push for id \(bookingId) — fetching offer details…")

            // Clear first. `onChange(of:)` only fires when the value actually
            // changes, so re-offering the SAME booking would decode to an equal
            // `BookingData`, fire nothing, and the popup would never open.
            bookingViewModel.incomingOffer = nil
            isAdminBookingOffer = false

            bookingViewModel.getBookingData(bookingId: bookingId)

        case .newAdminBooking:

            // `/booking` takes no parameters — the server resolves the
            // authenticated driver's pending admin offer on its own, so the
            // push's `booking_id` isn't sent, only logged for the trail.
            print("📥 New admin booking push for id \(payload.bookingId ?? "?") — fetching offer details…")

            bookingViewModel.incomingOffer = nil
            isAdminBookingOffer = true

            bookingViewModel.getAdminBookingData()

        case .customerCancelled:

            // Android: RouteDetailsActivity.myReceiver → status == "booking_cancel" → clientCancel()
            withAnimation(.easeInOut) {
                showRidePopup = false
            }

            bookingViewModel.incomingOffer = nil

            clearActiveBooking()

            toastManager.showToast(
                type: .error,
                title: "Booking Cancelled",
                subtitle: payload.message ?? "The customer cancelled this booking."
            )

        case .accountBlocked:

            // Android: MainActivity.myReceiver → status == block_status → blockProcess()
            homeViewModel.isBlocked = true

        case .none:
            break
        }
    }

    /// Called once the server confirms an ACCEPT — manual (via the popup's
    /// `onAccepted`) or automatic (via `pendingHomeAction` above). Adopts the
    /// booking as the active trip and draws its route, the visual equivalent of
    /// Android's `RouteDetailsActivity` map.
    func handleBookingAccepted() {

        guard let details = bookingViewModel.incomingOffer else { return }

        activeBookingId = details.bookingId ?? ""
        activeCustomerPhone = details.customerPhone ?? ""
        activePickupAddress = details.pickupAddress ?? ""
        activeDropAddress = details.dropAddress ?? ""
        activeBookingStatus = BookingAction.accept.rawValue
        tripStage = .pickupUser

        activeBookingIsAdmin = isAdminBookingOffer
        persistedAdminBookingId = isAdminBookingOffer ? activeBookingId : ""

        print("""
        ✅ Booking accepted — trip state captured from /get_bookdata:
           booking_id: \(activeBookingId.isEmpty ? "MISSING" : activeBookingId)
           cus_mob:    \(activeCustomerPhone.isEmpty ? "MISSING — MAKE CALL will have nothing to dial" : activeCustomerPhone)
        """)

        startRoute(for: details)
    }

    /// Puts the driver back into a trip that was already underway when the app
    /// was killed. Android makes this a manual step — the driver opens "Booking
    /// Page" from the menu and taps continue (`BookingPage.continue_booking()`);
    /// here it happens on its own the moment Home appears.
    func restoreTrip(from booking: BookingData) {

        guard let bookingId = booking.bookingId, !bookingId.isEmpty else { return }

        // Only accept/pickcustomer/onboard are resumable — same gate Android uses.
        // A completed or cancelled booking must not drag the driver back into it.
        guard let status = booking.bookingStatus,
              let stage = TripStage(assignStatus: status) else {
            print("ℹ️ Last booking \(booking.bookingId ?? "?") is not resumable (status: \(booking.bookingStatus ?? "nil")).")
            return
        }

        // Already on this exact trip: don't rebuild it, but do let the server
        // correct the stage if its status moved on while the app was away.
        if activeBookingId == bookingId {

            guard activeBookingStatus != status else { return }

            print("🔁 Server status for trip \(bookingId) moved \(activeBookingStatus) → \(status); re-staging.")

            activeBookingStatus = status
            withAnimation { tripStage = stage }
            return
        }

        // A different live trip on screen wins over a restore result that may have
        // been in flight while the driver accepted something new.
        guard activeBookingId.isEmpty else { return }

        print("🔄 Restoring trip \(bookingId) — server status '\(status)' → stage \(stage).")

        activeBookingId = bookingId
        activeCustomerPhone = booking.customerPhone ?? ""
        activePickupAddress = booking.pickupAddress ?? ""
        activeDropAddress = booking.dropAddress ?? ""
        activeBookingStatus = status
        tripStage = stage

        activeBookingIsAdmin = (bookingId == persistedAdminBookingId)

        // NOTE: deliberately does not write `incomingOffer`. Doing so is what made
        // relaunching mid-trip re-open the accept/reject popup for a job the driver
        // had already accepted. Everything the trip needs — id, phone, stage, route —
        // is taken from `booking` directly, right here.
        startRoute(
            for: booking,
            resuming: stage == .markCompleted ? .toDestination : .toPickup
        )

        toastManager.showToast(
            type: .success,
            title: "Trip Resumed",
            subtitle: "You have a trip in progress."
        )
    }

    func startRoute(for details: BookingData, resuming leg: RideLeg = .toPickup) {

        guard
            let latFromText = details.latFrom, let pickupLat = Double(latFromText),
            let longiFromText = details.longiFrom, let pickupLng = Double(longiFromText),
            let latToText = details.latTo, let dropLat = Double(latToText),
            let longiToText = details.longiTo, let dropLng = Double(longiToText)
        else { return }

        let pickup = CLLocationCoordinate2D(latitude: pickupLat, longitude: pickupLng)
        let destination = CLLocationCoordinate2D(latitude: dropLat, longitude: dropLng)

        // Falls back to the pickup point itself if we don't have a GPS fix yet —
        // still shows the pickup pin, just without a from-here route on the first frame.
        let currentLocation = locationService.currentLocation?.coordinate ?? pickup

        navigationViewModel.startRide(
            from: currentLocation,
            pickup: pickup,
            destination: destination,
            resuming: leg
        )
    }

    /// Ends trip-scoped state — customer cancellation (push) or driver-initiated
    /// cancel (CANCEL button) both funnel here.
    /// Driver has arrived and tapped START TRIP.
    ///
    /// The code is issued here rather than earlier so it reaches the customer at
    /// the moment they need to read it out — and so it can't go stale sitting in
    /// an SMS while the driver is still ten minutes away.
    func beginOTPVerification() {

        bookingViewModel.otpState = nil
        bookingViewModel.sendRideOTP(bookingId: activeBookingId)

        withAnimation(.easeInOut(duration: 0.25)) {
            showOTPView = true
        }
    }

    /// Reached only from `OTPVerificationSheet`'s `onVerified` — the server has
    /// confirmed the code, so now the trip may actually start.
    func startTripAfterOTP() {

        toastManager.showToast(
            type: .success,
            title: "OTP Verified",
            subtitle: "Starting the trip."
        )

        pendingHomeAction = .onboard

        bookingViewModel.changeBookingStatus(
            bookingId: activeBookingId,
            action: .onboard
        )
    }

    /// Admin-booking counterpart of `startTripAfterOTP()` — posts `onboard`
    /// directly, with neither `send_ride_otp` nor `verify_ride_otp` ever
    /// called. Reached only when `activeBookingIsAdmin` is true.
    func startTripWithoutOTP() {

        pendingHomeAction = .onboard

        bookingViewModel.changeBookingStatus(
            bookingId: activeBookingId,
            action: .onboard
        )
    }

    func clearActiveBooking() {
        activeBookingId = ""
        activeCustomerPhone = ""
        activePickupAddress = ""
        activeDropAddress = ""
        activeBookingStatus = ""
        tripStage = .pickupUser
        activeBookingIsAdmin = false
        persistedAdminBookingId = ""
        navigationViewModel.stopRide()
    }

    /// Android: `RouteDetailsActivity.onClick` → `btn_Call`/`btn_Call1` →
    /// `ACTION_DIAL` on `tel:` + `cus_mobile`, guarded by an is-empty check.
    /// iOS's `tel://` is the equivalent — it raises the system "Call <number>?"
    /// confirmation rather than dialling silently.
    /// Same contract as `callCustomer()`, one scheme along. Android has no
    /// equivalent — its SMS button posts the ride OTP — but a driver who can't
    /// reach someone by phone should be able to text them.
    /// Opens the booking's chat thread. Requires only the booking id, so it
    /// works even when `cus_mob` came back empty.
    func openChat() {

        guard !activeBookingId.isEmpty else {

            toastManager.showToast(
                type: .error,
                title: "No Booking",
                subtitle: "There's no active booking to chat about."
            )

            return
        }

        router.push(.chat(bookingId: activeBookingId))
    }

    func callCustomer() {

        // Android guards with `if (!cus_mobile.isEmpty())` and simply does nothing.
        // Saying so out loud is friendlier than a dead-feeling button.
        guard !activeCustomerPhone.isEmpty else {
            toastManager.showToast(
                type: .error,
                title: "No Number",
                subtitle: "This booking has no customer contact number."
            )
            return
        }

        // `cus_mob` can arrive with spaces or punctuation ("0113 277 2299"), which
        // makes an invalid tel: URL — keep only what a dialler accepts.
        let dialable = activeCustomerPhone.filter { $0.isNumber || $0 == "+" }

        guard let url = URL(string: "tel://\(dialable)"),
              UIApplication.shared.canOpenURL(url) else {

            // Simulator has no phone app, so canOpenURL is false there — this is
            // expected off-device rather than a failure worth alarming about.
            toastManager.showToast(
                type: .error,
                title: "Can't Call",
                subtitle: "Calling isn't available on this device."
            )
            return
        }

        UIApplication.shared.open(url)
    }

    func handleMenuNavigation(_ menu: SideMenuRowType) {

        switch menu {

        case .jobHistory:
            router.push(.jobHistory)

        case .paymentHistory:
            router.push(.paymentHistory)

        case .bankDetails:
            router.push(.bankDetails)

        case .profile:
            router.push(.profile)

        case .changePassword:
            router.push(.changePassword)

        case .emergency:
            router.push(.emergency)

        case .bookingPage:
            router.push(.booking)

        case .logout:
            showLogoutAlert = true
        }
    }
}

#Preview {
    HomeScreen()
}
