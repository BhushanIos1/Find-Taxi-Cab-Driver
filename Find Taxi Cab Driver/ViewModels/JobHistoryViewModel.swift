//
//  JobHistoryViewModel.swift
//  Find Taxi Cab Driver
//
//  Created by Claude on 08/09/26.
//

import Foundation

@MainActor
final class JobHistoryViewModel: ObservableObject {

    @Published var jobs: [JobHistoryModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    /// `POST /driver_book_list` with `{driver_id}` — the same call Android makes in
    /// `JobHistoryActivity.loadJobHistory()`.
    func loadJobHistory() {

        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil

        Task {

            defer { isLoading = false }

            do {

                let response: JobHistoryResponse = try await APIClient.shared.request(
                    DriverAPI.bookingList,
                    responseType: JobHistoryResponse.self
                )

                // Android's list is shown with `setReverseLayout(true)`, so the most
                // recent job reads first. Reversing here keeps that ordering without
                // the view having to know about it.
                jobs = (response.bookingData ?? []).reversed()

                // A refused call and a driver with no jobs yet both arrive here
                // with an empty list. Keeping the server's reason apart from
                // "nothing to show" is the difference between the screen
                // explaining itself and just looking blank.
                if jobs.isEmpty, response.result?.lowercased() != "success" {
                    errorMessage = response.message
                }

                print("📋 JOB HISTORY: \(jobs.count) job(s)")

            } catch {

                print("❌ JOB HISTORY ERROR:", error)
                errorMessage = error.localizedDescription
                jobs = []
            }
        }
    }
}
