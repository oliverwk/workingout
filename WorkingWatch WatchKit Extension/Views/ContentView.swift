//
//  ContentView.swift
//  WorkingWatch WatchKit Extension
//
//  Created by Olivier Wittop Koning on 23/01/2022.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    var workoutTypes: HKWorkoutActivityType = .highIntensityIntervalTraining
    

        var body: some View {
                NavigationView {
                    NavigationLink(destination: SessionPagingView(), tag: true, selection: $workoutManager.started) {
                        Text("HITT")
                            .font(.title3)
                            .foregroundColor(.green)
                        
                    }
                }
            
            .navigationBarTitle(Text("Workouts"))
            .onAppear {
                workoutManager.requestAuthorization()
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environmentObject(WorkoutManager())
    }
}
