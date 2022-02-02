//
//  RingManager.swift
//  WorkingWatch WatchKit Extension
//
//  Created by Olivier Wittop Koning on 23/01/2022.
//
import Foundation
import Combine

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
            print("No watch connction")
        }
        
        if HKHealthStore.isHealthDataAvailable() {
            let allTypes = Set([HKObjectType.workoutType(), HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!, HKObjectType.quantityType(forIdentifier: .heartRate)!])
            let allTypesAndMinutes = Set([HKObjectType.workoutType(), HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!, HKObjectType.quantityType(forIdentifier: .heartRate)!, HKObjectType.quantityType(forIdentifier: .appleExerciseTime)!])
            healthStore.requestAuthorization(toShare: allTypes, read: allTypesAndMinutes) { (success, error) in
                self.CanGetHeathKitData = success
                if !success {
                    print("Error with getting healthkit things \(error.debugDescription)")
                    // Handle the error here.
                } else {
                    self.GetHealthKitStatistics(type: HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!) { quantity, stat in
                        let value = quantity.doubleValue(for: HKUnit.kilocalorie())
                        print("kcals from healthkit: \(value) at date \(stat.startDate)")
                        DispatchQueue.main.async {
                            self.kcal = CGFloat(value)
                            self.KcalForRing = CGFloat(value)
                            self.DataFromWatch = false
                        }
                    }
                    self.GetHealthKitStatistics(type: HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!) { quantity, stat in
                        let value = quantity.doubleValue(for: HKUnit.minute())
                        print("mins from healthkit: \(value) at date \(stat.startDate)")
                        DispatchQueue.main.async {
                            self.mins = CGFloat(value)
                            self.MinsForRing = CGFloat(value)
                            self.DataFromWatch = false
                        }
                    }
                    self.GetHealthKitSample(sampleType: HKQuantityType.quantityType(forIdentifier: .heartRate)!) { heartreate in
                        print("heartreate from healthkit: \(heartreate)")
                        DispatchQueue.main.async {
                            self.heartRate = heartreate
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - HealthKit Helpers
    
    func GetHealthKitSample(sampleType: HKQuantityType, SampleDone: @escaping (_ sample: Double) -> Void) {
        let mostRecentPredicate = HKQuery.predicateForSamples(withStart: Date().today, end: Date(timeIntervalSince1970: (Date().timeIntervalSince1970 + 86400)), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: mostRecentPredicate, limit: 1, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            guard let samples = samples, let mostRecentSample = samples.first as? HKQuantitySample else {
                if let error = error {
                    print("the err: \(error.localizedDescription), couldn't get a smaple")
                }
                print("Things didn't work: \(String(describing: samples))")
                return
            }
            let heartreate = mostRecentSample.quantity.doubleValue(for: (sampleType == HKSampleType.quantityType(forIdentifier: .heartRate)! ? HKUnit(from: "count/min") : HKUnit.minute()))
            SampleDone(heartreate)
        }
        HKHealthStore().execute(sampleQuery)
    }
    
    func GetHealthKitStatistics(type: HKQuantityType, SampleDone: @escaping (_ sample: HKQuantity, _ statistic: HKStatistics) -> Void) {
        let lastDay = Date().today!
        var interval = DateComponents()
        interval.day = 1
        // Create the query
        let query = HKStatisticsCollectionQuery(quantityType: type, quantitySamplePredicate: nil, options: .cumulativeSum, anchorDate: lastDay, intervalComponents: interval)
        
        // Set the results handler
        query.initialResultsHandler = {
            query, results, error in
            
            guard let statsCollection = results else {
                // Perform proper error handling here
                print("*** An error occurred while calculating the statistics: \(String(describing: error?.localizedDescription)) ***")
                return
            }
            let endDate = Date()
            statsCollection.enumerateStatistics(from: lastDay, to: endDate, with: { (statistics, stop) in
                if let quantity = statistics.sumQuantity() {
                    SampleDone(quantity, statistics)
                } else {
                    print("didn't find any stats about \(type.debugDescription)")
                }
            })
        }
        healthStore.execute(query)
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
        print("activationDidCompleteWith with activationState: \(activationState.rawValue) hope it is 2 or 0 if it is 1 deactive")
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
        
        print("didReceiveMessage: \(message.debugDescription)")
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
        print("sessionDidBecomeInactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // add a timer to make sure the time keeps running and delete the heart rate shit
        print("sessionDidDeactivate")
    }
}
#endif
