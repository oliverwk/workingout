//
//  ZeilDagActiviteitenView.swift
//  WorkingOut (iOS)
//
//  Created by Olivier Wittop Koning on 14/07/2022.
//

import SwiftUI

struct ZeilDagActiviteitenView: View {
    @StateObject private var dagDeelInfo: DagDeelInfo
    @EnvironmentObject var zeilHealthManager: ZeilHealthManager
    let dagDeelNaam: String
    @State private var showingAlert = false

    init(_ dagDeel: DagDeel) {
        _dagDeelInfo = StateObject(wrappedValue: DagDeelInfo(dagDeel))
        self.dagDeelNaam = dagDeel == .ochtend ? "ochtend" : (dagDeel == .middag ? "middag" : "avond")
    }
    
    var body: some View {
        VStack {
            Form {
                Section(header: Text("De \(dagDeelNaam)")) {
                    Picker("Activiteit", selection: $dagDeelInfo.activiteit) {
                        Text("Zeilen").tag(Activiteit.zeilen)
                        Text("Zwemmen").tag(Activiteit.zwemmen)
                        Text("kaarten").tag(Activiteit.kaarten)
                        Text("Half-zeilen/half-kaarten").tag(Activiteit.halfZeilen_halfKaarten)
                        Text("Overige").tag(Activiteit.other)
                    }
                    Slider(value: $dagDeelInfo.AfstandAfgelegd, in: 0...50)
                    Text("Current Afstand: \($dagDeelInfo.AfstandAfgelegd.wrappedValue.formatted(.number.precision(.fractionLength(0)))) km")
                    Toggle("Was er regen/onweer", isOn: $dagDeelInfo.onweerEnRegen)
                    TextField("Opmerkingen", text: $dagDeelInfo.opmerkingenHealthkitNotes)
                }
                Section(header: Text("Overide")) {
                    DatePicker(selection: $dagDeelInfo.tijdRange[0], label: { Text("Datum/tijd begin") })
                    DatePicker(selection: $dagDeelInfo.tijdRange[1], label: { Text("Datum/tijd einde") })
                    Slider(value: $dagDeelInfo.Cals, in: 0...1000, step: 10)
                    Text("Cals to add to HealthKit: \($dagDeelInfo.Cals.wrappedValue.formatted(.number.precision(.fractionLength(0))))")
                }
            }
            Button("Submit Dagdeel") {
                Task {
                    await zeilHealthManager.AddWorkout(dagDeelInfo.WKtype, activiteitDagDeel: dagDeelInfo)
                    showingAlert = true
                }
            }.buttonStyle(.borderedProminent)
        }.alert("Succfully added workout to healthkit", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        }
    }
}
