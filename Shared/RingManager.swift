//
//  RingManager.swift
//  WorkingOut
//
//  Created by Olivier Wittop Koning on 23/01/2022.
//
import Foundation
import Combine
import os

let logger = Logger(
    subsystem: "nl.wittopkoning.WorkingOut",
    category: "RingManager"
)

#if os(macOS)
class RingManager: ObservableObject {
    @Published var kcal: CGFloat
    @Published var KcalForRing: CGFloat
    @Published var MinsForRing: CGFloat
    @Published var mins: CGFloat
    @Published var heartRate: Double
    @Published var started: Bool
    @Published var startedDate: Date?
    @Published var DataFromWatch: Bool
    @Published var timer: Timer.TimerPublisher
    @Published var cancelTimer: Cancellable?
    @Published var currentDate: Date
    var CanGetHeathKitData = false
    
    init() {
        self.kcal = 0.0
        self.heartRate = 0.0
        self.mins = 0
        self.MinsForRing = 0
        self.KcalForRing = 0.0
        self.started = false
        self.DataFromWatch = false
        self.currentDate = Date()
        self.timer = Timer.publish(every: 1, on: .main, in: .common)
        self.startedDate = nil
        cancelTimer = nil
    }
}
#endif

#if !os(macOS)
import WatchConnectivity
import HealthKit
import SwiftUI

class RingManager: NSObject, ObservableObject, WCSessionDelegate {
    
    @Published var kcal: CGFloat
    @Published var KcalForRing: CGFloat
    @Published var MinsForRing: CGFloat
    @Published var mins: CGFloat
    @Published var heartRate: Double
    @Published var started: Bool
    @Published var startedDate: Date?
    @Published var DataFromWatch: Bool
    @Published var timer: Timer.TimerPublisher
    @Published var cancelTimer: Cancellable?
    @Published var currentDate: Date
    var LastKcals: CGFloat
    var CanGetHeathKitData: Bool
    var healthStore: HKHealthStore
    
    override init() {
        self.kcal = 0.0
        self.heartRate = 0.0
        self.mins = 0
        self.MinsForRing = 0
        self.KcalForRing = 0.0
        self.LastKcals = 0.0
        self.started = false
        self.DataFromWatch = false
        self.currentDate = Date()
        self.timer = Timer.publish(every: 1, on: .main, in: .common)
        self.startedDate = nil
        cancelTimer = nil
        CanGetHeathKitData = false
        healthStore = HKHealthStore()
        super.init()
        
        
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        } else {
            logger.log("No watch connection")
        }
        
        Task(priority: .high) {
            await GetHealthData()
        }
        
    }
    
    
    
    func GetHealthData() async -> Void {
        if HKHealthStore.isHealthDataAvailable() {
            let allTypes = Set([HKObjectType.workoutType(), HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!, HKObjectType.quantityType(forIdentifier: .heartRate)!])
            let allTypesAndMinutes = Set([HKObjectType.workoutType(), HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!, HKObjectType.quantityType(forIdentifier: .heartRate)!, HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!])
            do {
                try await healthStore.requestAuthorization(toShare: allTypes, read: allTypesAndMinutes)
                self.CanGetHeathKitData = true
                logger.log("Got the health authorization")
            } catch let error {
                logger.error("Error with getting healthkit authorization \(error.localizedDescription, privacy: .public)")
                self.CanGetHeathKitData = false
                // Handle the error here.
                return
            }
            
            let (calorie, caloriesStats) = await GetHealthKitStatistics(type: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!)
            let calorieEnergy = calorie.doubleValue(for: HKUnit.kilocalorie())
            logger.log("kcals from healthkit: \(calorieEnergy, privacy: .public) at date \(caloriesStats.startDate, privacy: .public)")
            DispatchQueue.main.async {
                self.kcal = CGFloat(calorieEnergy)
                self.KcalForRing = CGFloat(calorieEnergy)
                self.DataFromWatch = false
            }

            let (minutes, MinutesStats) = await GetHealthKitStatistics(type: HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!)
            let minutesExercise = minutes.doubleValue(for: HKUnit.minute())
            logger.log("minutes from healthkit: \(minutesExercise, privacy: .public) at date \(MinutesStats.startDate, privacy: .public)")
            DispatchQueue.main.async {
                self.mins = CGFloat(minutesExercise)
                self.MinsForRing = CGFloat(minutesExercise)
                self.DataFromWatch = false
            }
            
            let heartRate = await GetHealthKitSample(sampleType: HKQuantityType.quantityType(forIdentifier: .heartRate)!)
            logger.log("heartRate from healthkit: \(heartRate, privacy: .public)")
            DispatchQueue.main.async { self.heartRate = heartRate }
        }
    }
    // MARK: - HealthKit Helpers
    
    func GetHealthKitSample(sampleType: HKQuantityType) async -> Double {
        let mostRecentPredicate = HKQuery.predicateForSamples(withStart: Date().today, end: Date(timeIntervalSince1970: (Date().timeIntervalSince1970 + 86400)), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: mostRecentPredicate, limit: 1, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
                guard let samples1 = samples, let mostRecentSample = samples1.first as? HKQuantitySample else {
                    if let error = error {
                        logger.log("couldn't get a \(sampleType.debugDescription) sample: \(error.localizedDescription, privacy: .public)")
                    }
                    logger.log("While getting the \(sampleType.debugDescription) sample coulnd't convert the value: \(String(describing: samples), privacy: .public)")
                    return
                }
                let heartreate = mostRecentSample.quantity.doubleValue(for: (sampleType == HKSampleType.quantityType(forIdentifier: .heartRate)! ? HKUnit(from: "count/min") : HKUnit.minute()))
                continuation.resume(returning: heartreate)
            }
            healthStore.execute(sampleQuery)
        }
    }
    
    
    func GetHealthKitStatistics(type: HKQuantityType) async -> (sample: HKQuantity, statistic: HKStatistics) {
        let lastDay = Date().today!
        var interval = DateComponents()
        interval.day = 1
        // Create the query
        let query = HKStatisticsCollectionQuery(quantityType: type, quantitySamplePredicate: nil, options: .cumulativeSum, anchorDate: lastDay, intervalComponents: interval)
        
        // Set the results handler
        return await withCheckedContinuation { continuation in
            query.initialResultsHandler = {
                query1, results, error1 in
                
                guard let statsCollection = results else {
                    // Perform proper error handling here
                    logger.error("*** An error occurred while calculating the statistics: \(String(describing: error1?.localizedDescription), privacy: .public) ***")
                    return
                }
                let endDate = Date()
                statsCollection.enumerateStatistics(from: lastDay, to: endDate, with: { (statistics, stop) in
                    if let quantity = statistics.sumQuantity() {
                        continuation.resume(returning: (quantity, statistics))
                    } else {
                        logger.log("Didn't find any stats about \(type.debugDescription, privacy: .public)")
                    }
                })
            }
            healthStore.execute(query)
        }
    }
    
    func HeahtlKitSummary() -> HKActivitySummary {
        let s = HKActivitySummary()
        s.activeEnergyBurnedGoal = HKQuantity(unit: HKUnit(from: .kilocalorie), doubleValue: 600)
        s.appleExerciseTimeGoal = HKQuantity(unit: HKUnit.minute(), doubleValue: 30)
        s.appleStandHoursGoal = HKQuantity(unit: HKUnit.count(), doubleValue: 10)
        
        s.activeEnergyBurned = HKQuantity(unit: HKUnit(from: .kilocalorie), doubleValue: self.KcalForRing)
        s.appleExerciseTime = HKQuantity(unit: HKUnit.minute(), doubleValue: self.MinsForRing)
        s.appleStandHours = HKQuantity(unit: HKUnit.count(), doubleValue: 10)
        
        return s
    }
    
    // MARK: - WatchConntion Stuff
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        logger.log("activationDidCompleteWith with activationState: \(activationState.rawValue, privacy: .public) hope it is 2 or 0 if it is 1 deactive")
    }
    
    //    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        if !self.started {
            DispatchQueue.main.async {
                self.started = true
                self.DataFromWatch = true
                self.startedDate = Date()
            }
        }
        
        logger.log("didReceiveMessage: \(message.debugDescription, privacy: .public)")
        DispatchQueue.main.async {
            self.heartRate = message["heartRate"] as! Double
            self.mins = message["mins"] as! CGFloat
            self.kcal = message["kcals"] as! CGFloat
            
            self.KcalForRing += (message["kcals"] as! CGFloat) - self.LastKcals
            self.LastKcals = message["kcals"] as! CGFloat
        }
        replyHandler(["gotit": true])
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        // add a timer to make sure the time keeps running and delete the heart rate shit
        logger.log("sessionDidBecomeInactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // add a timer to make sure the time keeps running and delete the heart rate shit
        logger.log("sessionDidDeactivate")
    }
}
#endif
