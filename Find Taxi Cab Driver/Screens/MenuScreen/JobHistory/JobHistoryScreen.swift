//
//  HostroyScreen.swift
//  Find Taxi Cab
//
//  Created by Bhushan Kumar on 01/03/26.
//

import SwiftUI

struct JobHistoryScreen: View {
    
    @EnvironmentObject
    private var router: AppRouter
    
    let bookings: [JobHistoryModel] = [
        JobHistoryModel(
            status: "Abandoned",
            jobNumber: "932",
            jobDate: "07/02/2026",
            time: "13:39:37",
            pickup: "Hindmotor, Uttarpara, West Bengal, India",
            drop: "Rishra, Pandit Satghara, West Bengal, India",
            paymentMode: "Cash",
            specialMessage: "",
            specialNeed: "No",
            fare: "£ 0"
        ),
        JobHistoryModel(
            status: "Abandoned",
            jobNumber: "932",
            jobDate: "07/02/2026",
            time: "13:39:37",
            pickup: "Hindmotor, Uttarpara, West Bengal, India",
            drop: "Rishra, Pandit Satghara, West Bengal, India",
            paymentMode: "Cash",
            specialMessage: "",
            specialNeed: "No",
            fare: "£ 0"
        ),
        JobHistoryModel(
            status: "Abandoned",
            jobNumber: "932",
            jobDate: "07/02/2026",
            time: "13:39:37",
            pickup: "Hindmotor, Uttarpara, West Bengal, India",
            drop: "Rishra, Pandit Satghara, West Bengal, India",
            paymentMode: "Cash",
            specialMessage: "",
            specialNeed: "No",
            fare: "£ 0"
        ),
        JobHistoryModel(
            status: "Abandoned",
            jobNumber: "932",
            jobDate: "07/02/2026",
            time: "13:39:37",
            pickup: "Hindmotor, Uttarpara, West Bengal, India",
            drop: "Rishra, Pandit Satghara, West Bengal, India",
            paymentMode: "Cash",
            specialMessage: "",
            specialNeed: "No",
            fare: "£ 0"
        )
    ]
    
    var body: some View {
        
        ZStack {
            
            ScrollView {
                
                LazyVStack(spacing: 20) {
                    ForEach(bookings) { booking in
                        JobHistoryCell(item: booking)
                    }
                }
                .padding(20)
            }
        }
        .appNavigationBar(
            title: "Job History",
            leading: .back) {
                router.pop()
            }
    }
}

#Preview {
    JobHistoryScreen()
}
