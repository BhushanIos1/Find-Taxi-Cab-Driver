//
//  RideTimerManager.swift
//  Find Taxi Cab Driver
//
//  Created by Bhushan Kumar on 21/03/26.
//

import SwiftUI
import Combine

final class RideTimerManager: ObservableObject {
    
    @Published var remainingTime: Int = 15
    
    private var endDate: Date?
    private var cancellable: AnyCancellable?
    
    func start(duration: Int) {
        endDate = Date().addingTimeInterval(TimeInterval(duration))
        startTicker()
    }
    
    private func startTicker() {
        cancellable?.cancel()
        
        cancellable = Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateRemainingTime()
            }
    }
    
    private func updateRemainingTime() {
        guard let endDate else { return }
        
        let remaining = Int(endDate.timeIntervalSinceNow.rounded())
        
        if remaining <= 0 {
            remainingTime = 0
            stop()
        } else {
            remainingTime = remaining
        }
    }
    
    func stop() {
        cancellable?.cancel()
        cancellable = nil
    }
}
