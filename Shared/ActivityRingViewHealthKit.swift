//
//  ActivityRingViewHealthKit.swift
//  WorkingOut
//
//  Created by Olivier Wittop Koning on 02/02/2022.
//

import SwiftUI

import SwiftUI
import HealthKitUI

struct ActivityRingViewHealthKit: UIViewRepresentable {
    
    var activitySummary: HKActivitySummary
    
    func makeUIView(context: Context) -> HKActivityRingView {
        let view = HKActivityRingView()
        return view
    }
    
    func updateUIView(_ uiView: HKActivityRingView, context: Context) {
        uiView.activitySummary = self.activitySummary
    }
}

struct ActivityRingViewHealthKit_Previews: PreviewProvider {
    static var sampleSummary: HKActivitySummary {
        let s = HKActivitySummary()
        s.activeEnergyBurnedGoal = HKQuantity(unit: HKUnit(from: .kilocalorie), doubleValue: 600)
        s.activeEnergyBurned = HKQuantity(unit: HKUnit(from: .kilocalorie), doubleValue: 250)
        s.appleExerciseTimeGoal = HKQuantity(unit: HKUnit.minute(), doubleValue: 30)
        s.appleExerciseTime = HKQuantity(unit: HKUnit.minute(), doubleValue: 20)
        s.appleStandHoursGoal = HKQuantity(unit: HKUnit.count(), doubleValue: 10)
        s.appleStandHours = HKQuantity(unit: HKUnit.count(), doubleValue: 8)
        return s
    }
    static var previews: some View {
        ActivityRingViewHealthKit(activitySummary: sampleSummary)
            .frame(width: 200, height: 200, alignment: .center)
    }
}
