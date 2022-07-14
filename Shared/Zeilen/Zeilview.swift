//
//  Zeilview.swift
//  WorkingOut (iOS)
//
//  Created by Olivier Wittop Koning on 14/07/2022.
//

import SwiftUI

struct ZeilView: View {
    @StateObject var zeilHealthManager = ZeilHealthManager()
    @State var fillRings = Bool() {
        willSet {
            let dagDeelExample = DagDeelInfo(.ochtend)
            dagDeelExample.activiteit = .other
            dagDeelExample.Cals = 600
            Task(priority: .high) {
                await zeilHealthManager.AddWorkout(.sailing, activiteitDagDeel: dagDeelExample)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                NavigationLink("Ochtend") {
                    ZeilDagActiviteitenView(.ochtend).environmentObject(zeilHealthManager)
                }
                NavigationLink("Middag") {
                    ZeilDagActiviteitenView(.middag).environmentObject(zeilHealthManager)
                }
                NavigationLink("Avond") {
                    ZeilDagActiviteitenView(.SpelTijd).environmentObject(zeilHealthManager)
                }.navigationBarBackButtonHidden(true)
            }
            Toggle("fillRings", isOn: $fillRings)
        }.navigationTitle(Text("Zeilen")).navigationBarTitleDisplayMode(.large).navigationBarBackButtonHidden(true)
    }
}
