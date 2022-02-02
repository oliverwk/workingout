//
//  WorkingOutApp.swift
//  WorkingWatch WatchKit Extension
//
//  Created by Olivier Wittop Koning on 23/01/2022.
//

import SwiftUI

@main
struct WorkingOutApp: App {
    @StateObject private var workoutManager = WorkoutManager()
    
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }.environmentObject(workoutManager)
        }
    }
}
