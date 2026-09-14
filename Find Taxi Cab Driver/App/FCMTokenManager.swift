//
//  FCMTokenManager.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 12/04/26.
//

import SwiftUI
import FirebaseMessaging

/// Owns the FCM token end to end: local storage plus registering it with the backend.
/// Android does this with two redundant call sites (`SplashActivity.updateToken()` and
/// `PermissionActivity.updateToken()`) each posting `{driver_id, token}` to
/// `api/update_drivertoken`. Here it's consolidated into one place — every path that
/// obtains a token (initial fetch, rotation, manual refresh) funnels through
/// `updateToken(_:)`, which syncs to the server whenever a driver session exists.
final class FCMTokenManager: ObservableObject {

    static let shared = FCMTokenManager()

    @AppStorage("fcmToken") private var storedToken: String = ""

    private init() {}

    var token: String? {
        storedToken.isEmpty ? nil : storedToken
    }

    func getToken() -> String? {
        token
    }

    func refreshToken(completion: ((String?) -> Void)? = nil) {
        Messaging.messaging().token { [weak self] token, error in

            guard let self = self else { return }

            if let token = token {
                self.updateToken(token)
                completion?(token)
            } else {
                completion?(nil)
            }
        }
    }

    /// Stores the token locally and, if a driver is logged in, pushes it to the server
    /// right away. Called on every launch (via `Messaging`'s registration-token
    /// callback) as well as on rotation, so a returning logged-in driver's token stays
    /// in sync without needing a dedicated "resync on launch" call like Android has.
    func updateToken(_ token: String) {
        storedToken = token
        registerWithServerIfLoggedIn()
    }

    /// Posts `{driver_id, token}` to `api/update_drivertoken` — same endpoint and
    /// parameters as the Android app's `updateToken()`. No-ops silently when there's
    /// no active session, matching Android's "only sync if already logged in" guard
    /// in `SplashActivity.redirectHome()`.
    func registerWithServerIfLoggedIn() {

        guard let token, AuthManager.shared.isLoggedIn else { return }

        Task {
            do {
                let response: CommonResponse = try await APIClient.shared.request(
                    DriverAPI.updateFCMToken(token: token),
                    responseType: CommonResponse.self
                )
                print("✅ FCM TOKEN SYNCED:", response.result ?? "")
            } catch {
                print("❌ FCM TOKEN SYNC ERROR:", error)
            }
        }
    }

    func clearToken() {
        storedToken = ""
    }
}
