//
//  RingView.swift
//  WorkingOut (macOS)
//
//  Created by Olivier Wittop Koning on 02/02/2022.
//

import SwiftUI
import Foundation


struct HKActivitySummaryMacOS {
    var activityMoveMode: Int = 1
    
    var activeEnergyBurned: Int // HKQuantity
    
    var activeEnergyBurnedGoal: Int // HKQuantity
    
    var appleMoveTime: Int // HKQuantity
    
    var appleMoveTimeGoal: Int // HKQuantity
    
    var appleExerciseTime: Int // HKQuantity
    
    var appleExerciseTimeGoal: Int // HKQuantity
    
    var appleStandHours: Int // HKQuantity
    
    var appleStandHoursGoal: Int // HKQuantity
    
    enum HKCategoryValueAppleStandHour {
        case stood
        case idle
    }
    
    func dateComponents(for: Calendar) -> DateComponents {
        Calendar.current.dateComponents([.era, .year, .month, .day], from: Date())
    }
    
}

struct ActivityRingViewHealthKit: View {
    var activitySummary: Any
    
    var body: some View {
        VStack {
            ActivityRingView(progress: .constant(500), colors: [Color.darkRed, Color.lightRed, Color.outlineRed], RingSize: 100, fullRing: 600.0).fixedSize().padding()
            ActivityRingView(progress: .constant(15.0), colors: [Color.darkGreen, Color.lightGreen, Color.outlineGreen], RingSize: 62, fullRing: 30.0).fixedSize()
        }.preferredColorScheme(.dark)
    }
}

struct ActivityRingView: View {
    @Binding var progress: CGFloat
    let colors: [Color]
    let RingSize: Double
    let fullRing: Double
    
    
    var body: some View {
        withAnimation(.spring(response: 0.6, dampingFraction: 1.0, blendDuration: 1.0)) {
            ZStack {
                Circle()
                    .stroke(colors[2], lineWidth: 15)
                Circle()
                    .trim(from: 0, to: ((progress-(progress > fullRing ? fullRing : 0))/fullRing))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: colors),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 15, lineCap: .round)
                    ).rotationEffect(.degrees(-90))
                Circle()
                    .frame(width: 15, height: 15)
                    .foregroundColor(colors[0])
                    .offset(y: -1*RingSize/2)
                Circle()
                    .frame(width: 15, height: 15)
                    .foregroundColor(progress > 0.95 ? colors[1]: colors[1].opacity(0))
                    .offset(y: -1*RingSize/2)
                    .rotationEffect(Angle.degrees(360 * Double((progress-(progress > fullRing ? fullRing : 0))/fullRing)))
                    .shadow(color: Double((progress-(progress > fullRing ? fullRing : 0))/fullRing) > 0.96 ? Color.black.opacity(0.1): Color.clear, radius: 3, x: 4, y: 0)
            }.frame(idealWidth: RingSize, idealHeight: RingSize, alignment: .center).background(.white)
        }
    }
}

struct ActivityRingView_Previews: PreviewProvider {
    static var previews: some View {
        ActivityRingViewHealthKit(activitySummary: HKActivitySummaryMacOS(activeEnergyBurned: 1, activeEnergyBurnedGoal: 1, appleMoveTime: 1, appleMoveTimeGoal: 1, appleExerciseTime: 1, appleExerciseTimeGoal: 1, appleStandHours: 1, appleStandHoursGoal: 1))
    }
}
