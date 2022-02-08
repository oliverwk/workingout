//
//  CongratsView.swift
//  WorkingWatch WatchKit Extension
//
//  Created by Olivier Wittop Koning on 08/02/2022.
//

import SwiftUI
import HealthKit
import WatchKit

struct CongratsView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading) {
                ActivityRingsView(HealthStore: workoutManager.healthStore)
                    .padding()
                Spacer()
                Text("Congrats with closing your rings")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.leading)
            }
        }
    }
}

struct ActivityRingsView: WKInterfaceObjectRepresentable {
    func updateWKInterfaceObject(_ wkInterfaceObject: WKInterfaceObjectType, context: Context) {
        
    }
    
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
}

struct CongratsViewProvider_Previews: PreviewProvider {
    static var previews: some View {
        CongratsView()
    }
}
