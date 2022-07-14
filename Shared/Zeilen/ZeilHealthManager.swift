//
//  ZeilHealthManager.swift
//  WorkingOut (iOS)
//
//  Created by Olivier Wittop Koning on 14/07/2022.
//

import HealthKit
import os.log

class ZeilHealthManager: ObservableObject {
    let logger = Logger(
        subsystem: "nl.wittopkoning.WorkingOut",
        category: "ZeilHealthManager"
    )
    var healthStore: HKHealthStore
    @Published var CanGetHealthStoreAcces = false
    init() {
        healthStore = HKHealthStore()
    }
    
    func AddWorkout(_ Type: HKWorkoutActivityType, activiteitDagDeel: DagDeelInfo) async {
        let energyBurned = HKQuantity(unit: HKUnit.largeCalorie(), doubleValue: activiteitDagDeel.Cals)
        
        var sail: HKWorkout
        if activiteitDagDeel.AfstandAfgelegd != 0 {
            let distance = HKQuantity(unit: HKUnit.meter(), doubleValue: (activiteitDagDeel.AfstandAfgelegd*1000*1000))
            sail = HKWorkout(activityType: HKWorkoutActivityType.sailing, start: activiteitDagDeel.tijdRange[0], end: activiteitDagDeel.tijdRange[1], duration: 0,
                                totalEnergyBurned: energyBurned,
                                totalDistance: distance,
                             metadata: ["opmerkingen":"\(activiteitDagDeel.opmerkingenHealthkitNotes)", "onweerEnRegen": activiteitDagDeel.onweerEnRegen, "calsIsCustom": activiteitDagDeel.calsIsCustom])
        } else {
            let distance = HKQuantity(unit: HKUnit.meter(), doubleValue: 20)
            sail = HKWorkout(activityType: HKWorkoutActivityType.sailing, start: activiteitDagDeel.tijdRange[0], end: activiteitDagDeel.tijdRange[1], duration: 0,
                                totalEnergyBurned: energyBurned,
                                totalDistance: distance,
                             metadata:  [" opmerkingen":"\(activiteitDagDeel.opmerkingenHealthkitNotes)", "onweerEnRegen": "\(activiteitDagDeel.onweerEnRegen.description)", "CaloriesAreCustom": "\(activiteitDagDeel.calsIsCustom.description)"])
        }
       
        let allTypesAndMinutes = Set([HKObjectType.workoutType(), HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!, HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!, HKObjectType.quantityType(forIdentifier: .stepCount)!, HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!])
        do {
            try await healthStore.requestAuthorization(toShare: allTypesAndMinutes, read: allTypesAndMinutes)
            logger.log("Got the health authorization")
            DispatchQueue.main.async { self.CanGetHealthStoreAcces = true }
        } catch let error {
            logger.error("Error with getting healthkit authorization \(error.localizedDescription, privacy: .public)")
            DispatchQueue.main.async { self.CanGetHealthStoreAcces = true }
        }
       
        do {
            try await healthStore.save(sail)
            logger.log("Added to the workout to HealthKit")
        } catch let error {
            logger.log("Failed while trying to add the sail workout to the HealthKit store with the error: \(error.localizedDescription, privacy: .public)")
        }
        var sailDetailSamples = [HKSample]()
        
        // Add extra info
        let meterCountType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)!

        let meterPerInterval = HKQuantity(unit: HKUnit.meterUnit(with: .kilo), doubleValue: (activiteitDagDeel.AfstandAfgelegd != 0) ? activiteitDagDeel.AfstandAfgelegd : 2.5)

        let meterPerIntervalSample = HKQuantitySample(type: meterCountType,
                             quantity: meterPerInterval,
                             start: activiteitDagDeel.tijdRange[0],
                             end: activiteitDagDeel.tijdRange[1])

        sailDetailSamples.append(meterPerIntervalSample)
        
        
        // Add extra info
        let stepCountType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!

        let stepCountPerInterval = HKQuantity(unit: HKUnit.count(), doubleValue: 2500.0)

        let setpCountdPerIntervalSample = HKQuantitySample(type: stepCountType,
                             quantity: stepCountPerInterval,
                             start: Date(timeIntervalSince1970: activiteitDagDeel.tijdRange[0].timeIntervalSince1970+3600),
                             end: activiteitDagDeel.tijdRange[1])

        sailDetailSamples.append(setpCountdPerIntervalSample)
        
        do {
            try await healthStore.addSamples(sailDetailSamples, to: sail)
            logger.log("added to the detail")
        } catch let error {
            logger.log("Failed while trying to add detail to the sail workout to the HealthKit store with the error: \(error.localizedDescription, privacy: .public)")
        }
    }
    
}
