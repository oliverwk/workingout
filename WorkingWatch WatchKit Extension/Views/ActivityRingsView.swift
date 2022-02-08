//
//  ActivityRingsView.swift
//  WorkingWatch WatchKit Extension
//
//  Created by Olivier Wittop Koning on 07/02/2022.
//

import Foundation
import HealthKit
import SwiftUI

struct ActivityRingsView: WKInterfaceObjectRepresentable {
    let healthStore: HKHealthStore
    var activityRingsObject: WKInterfaceActivityRing?
    
    init(HealthStore: HKHealthStore) {
        self.activityRingsObject = WKInterfaceActivityRing()
        self.healthStore = HealthStore
    }
    
    func makeWKInterfaceObject(context: Context) -> some WKInterfaceObject {
        
        let calendar = Calendar.current
        var components = calendar.dateComponents([.era, .year, .month, .day], from: Date())
        components.calendar = calendar
        
        let predicate = HKQuery.predicateForActivitySummary(with: components)
        let query = HKActivitySummaryQuery(predicate: predicate) { query, summaries, error in
            DispatchQueue.main.async {
                activityRingsObject?.setActivitySummary(summaries?.first, animated: true)
            }
        }
        query.updateHandler = { query, summaries, error in
            DispatchQueue.main.async {
                activityRingsObject?.setActivitySummary(summaries?.first, animated: true)
            }
        }

        healthStore.execute(query)
        
        return activityRingsObject!
    }
    
    func updateWKInterfaceObject(_ wkInterfaceObject: WKInterfaceObjectType, context: Context) {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.era, .year, .month, .day], from: Date())
        components.calendar = calendar
        
        let predicate = HKQuery.predicateForActivitySummary(with: components)
        let query = HKActivitySummaryQuery(predicate: predicate) { query, summaries, error in
            DispatchQueue.main.async {
                activityRingsObject?.setActivitySummary(summaries?.first, animated: true)
                print("activeEnergyBurned: \(String(describing: summaries?.first?.activeEnergyBurned))")
                print("appleExerciseTime: \(String(describing: summaries?.first?.appleExerciseTime))")
            }
        }
        /*query.updateHandler = { query, summaries, error in
            DispatchQueue.main.async {
                activityRingsObject?.setActivitySummary(summaries?.first, animated: true)
                print("activeEnergyBurned: \(String(describing: summaries?.first?.activeEnergyBurned))")
                print("appleExerciseTime: \(String(describing: summaries?.first?.appleExerciseTime))")
                let totalBurned = summaries?.first?.activeEnergyBurned
                let hoeveelnog = 600 - (totalBurned?.doubleValue(for: HKUnit.largeCalorie()))!
                let zoveelHebbenWeNuGehaaldInDeWorkout = 230.0
                let progrezz = zoveelHebbenWeNuGehaaldInDeWorkout/hoeveelnog
            }
        }*/
        healthStore.execute(query)
    }
}
