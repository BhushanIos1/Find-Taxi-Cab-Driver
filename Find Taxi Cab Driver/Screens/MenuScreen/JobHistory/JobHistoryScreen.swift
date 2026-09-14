//
//  HostroyScreen.swift
//  Find Taxi Cab
//
//  Created by Bhushan Kumar on 01/03/26.
//

import SwiftUI
import SwiftfulLoadingIndicators

struct JobHistoryScreen: View {

    @EnvironmentObject
    private var router: AppRouter

    @StateObject
    private var viewModel = JobHistoryViewModel()

    var body: some View {

        ZStack {

            if viewModel.jobs.isEmpty, !viewModel.isLoading {

                emptyState

            } else {

                ScrollView {

                    LazyVStack(spacing: 20) {
                        ForEach(viewModel.jobs) { job in
                            JobHistoryCell(item: job)
                        }
                    }
                    .padding(20)
                }
            }

            if viewModel.isLoading {

                LoadingIndicator(
                    animation: .circleTrim,
                    color: AppColors.primaryYellow,
                    size: .medium,
                    speed: .normal
                )
            }
        }
        .appNavigationBar(
            title: "Job History",
            leading: .back) {
                router.pop()
            }
        .onAppear {
            viewModel.loadJobHistory()
        }
    }
}

private extension JobHistoryScreen {

    /// Android surfaces this as a "No Job History!!!" toast; inline reads better
    /// on a screen whose entire job is to show a list.
    var emptyState: some View {

        NoDataView(
            icon: "clock.arrow.trianglehead.counterclockwise.rotate.90",
            message: viewModel.errorMessage ?? "You haven't completed any jobs yet."
        )
    }
}

#Preview {
    JobHistoryScreen()
}
