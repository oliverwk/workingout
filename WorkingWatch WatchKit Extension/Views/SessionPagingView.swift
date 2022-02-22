//
//  SessionPagingView.swift
//  WorkingWatch WatchKit Extension
//
//  Created by Olivier Wittop Koning on 23/01/2022.
//

import SwiftUI
import WatchKit
import os

struct SessionPagingView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.isLuminanceReduced) var isLuminanceReduced
    @State private var selection: Tab = .metrics
    @State private var showedAward: Bool = false
    let logger = Logger(
        subsystem: "nl.wittopkoning.WorkingOut",
        category: "SessionPagingView"
    )
    
    enum Tab {
        case controls, metrics, congrats
    }
    
    var body: some View {
        TabView(selection: $selection) {
            ControlsView().tag(Tab.controls)
            MetricsView().tag(Tab.metrics)
            if workoutManager.progrezz >= 1 {
                CongratsView().tag(Tab.congrats)
            }
        }
        // .navigationTitle("HITT, with growingannas")
        .navigationBarBackButtonHidden(true)
        .onChange(of: workoutManager.running) { _ in
            displayView(.metrics)
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: isLuminanceReduced ? .never : .automatic))
        .onChange(of: isLuminanceReduced) { _ in
            displayView(.metrics)
        }
        .onChange(of: workoutManager.progrezz) { _ in
            if !showedAward {
                if workoutManager.progrezz >= 1 {
                    logger.log("You got the rings, Nice!")
                    WKInterfaceDevice.current().play(.notification)
                    displayView(.congrats)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        displayView(.metrics)
                    }
                    showedAward = true
                }
            }
        }
        .onAppear {
            logger.log("Bonjour need to start training, becaue running: \(workoutManager.running)")
            if !workoutManager.running {
                workoutManager.startWorkout(workoutType: .highIntensityIntervalTraining)
            }
        }
    }
    
    func displayView(_ tab: Tab) {
        withAnimation {
            selection = tab
        }
    }
}

struct PagingView_Previews: PreviewProvider {
    static var previews: some View {
        SessionPagingView().environmentObject(WorkoutManager())
    }
}
