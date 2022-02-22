//
//  WorkoutManager.swift
//  WorkingOut
//
//  Created by Olivier Wittop Koning on 23/01/2022.
//

import os
import Foundation
import HealthKit
import WatchConnectivity

class WorkoutManager: NSObject, ObservableObject {
    let logger = Logger(
            subsystem: "nl.wittopkoning.WorkingOut",
            category: "WorkoutManager"
        )

    @Published var started: Bool? = false
    let LiveManager = SessionDelegater()
    var lastSendData = HealthData(kcals: 0.0, mins: 0, heartRate: 0.0) // This is for coms between the hpone and watch
    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = LiveManager
            session.activate()
        }
        GetInitialRingData()
    }
    
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?
    
    // Start the workout.
    func startWorkout(workoutType: HKWorkoutActivityType) {
        logger.debug("Starting the workout")
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = workoutType
        configuration.locationType = .indoor
        
        // Create the session and obtain the workout builder.
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
        } catch {
            // Handle any exceptions.
            logger.error("There was an erorr with building the workout: \(error.localizedDescription)")
            return
        }
        
        // Setup session and builder.
        session?.delegate = self
        builder?.delegate = self
        
        // Set the workout builder's data source.
        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                      workoutConfiguration: configuration)
        
        // Start the workout session and begin data collection.
        let startDate = Date()
        session?.startActivity(with: startDate)
        builder?.beginCollection(withStart: startDate) { (success, error) in
            // The workout has started.
            if success {
                self.logger.debug("The workout has started successfully")
            } else {
                self.logger.error("There was an error with the workout didn't start: \(error.debugDescription)")
            }
            // TODO: send start time to the iphone
        }
    }
    
    // Request authorization to access HealthKit.
    func requestAuthorization() {
        // The quantity type to write to the health store.
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]
        
        // The quantity types to read from the health store.
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.activitySummaryType(),
            HKObjectType.workoutType()
        ]
        
        // Request authorization for those quantity types.
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
            // Handle error.
            if !success {
                self.logger.error("HealthAuth error failed, with error: \(error.debugDescription)")
            } else {
                self.logger.log("HealthAuth successed")
            }
        }
    }
    
    // MARK: - Session State Control
    
    // The app's workout state.
    @Published var running = false
    
    func togglePause() {
        if running == true {
            self.pause()
        } else {
            resume()
        }
    }
    
    func pause() {
        session?.pause()
        // TODO: update time on the iphone
    }
    
    func resume() {
        session?.resume()
        // TODO: update time on the iphone
    }
    
    func endWorkout() {
        session?.end()
        self.started = false
    }
    
    // MARK: - Workout Metrics
    @Published var MinutesPased: Int = 0 {
        didSet {
            self.sendMessage(message: HealthData(kcals: self.activeEnergy, mins: self.MinutesPased, heartRate: self.heartRate))
        }
    }
    @Published var averageHeartRate: Double = 0 {
        didSet {
            self.sendMessage(message: HealthData(kcals: self.activeEnergy, mins: self.MinutesPased, heartRate: self.heartRate))
        }
    }
    @Published var heartRate: Double = 0 {
        didSet {
            self.sendMessage(message: HealthData(kcals: self.activeEnergy, mins: self.MinutesPased, heartRate: self.heartRate))
        }
    }
    @Published var activeEnergy: Double = 0.0 {
        didSet {
            self.sendMessage(message: HealthData(kcals: self.activeEnergy, mins: self.MinutesPased, heartRate: self.heartRate))
            self.progrezz = (self.activeEnergy+0.1)/abs(600 - (InitialRingData?.activeEnergyBurned.doubleValue(for: HKUnit.largeCalorie()))!)
            logger.log("PROGREZZ; \(self.progrezz) (\(self.activeEnergy+0.1))/(600 - (\(String(describing: self.InitialRingData?.activeEnergyBurned.doubleValue(for: HKUnit.largeCalorie())))!))")
        }
    }
    
    @Published var progrezz: Double = 0.0
    var InitialRingData: HKActivitySummary?
    
    @Published var workout: HKWorkout?
    
    
    func updateForStatistics(_ statistics: HKStatistics?) {
        guard let statistics = statistics else { return }
        
        DispatchQueue.main.async {
            switch statistics.quantityType {
            case HKQuantityType.quantityType(forIdentifier: .appleExerciseTime):
                let MinuteUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                self.MinutesPased = Int(statistics.mostRecentQuantity()?.doubleValue(for: MinuteUnit) ?? 0)
            case HKQuantityType.quantityType(forIdentifier: .heartRate):
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                self.heartRate = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                self.averageHeartRate = statistics.averageQuantity()?.doubleValue(for: heartRateUnit) ?? 0
            case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                let energyUnit = HKUnit.kilocalorie()
                self.activeEnergy = statistics.sumQuantity()?.doubleValue(for: energyUnit) ?? 0
            default:
                self.logger.log("statistics.quantityType: \(statistics.quantityType.debugDescription)")
                return
            }
        }
    }
    
    func GetInitialRingData() -> Void {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.era, .year, .month, .day], from: Date())
        components.calendar = calendar
        
        let predicate = HKQuery.predicateForActivitySummary(with: components)
        let query = HKActivitySummaryQuery(predicate: predicate) { query, summaries, error in
            DispatchQueue.main.async {
                self.logger.log("InitialRingData: \(String(describing: summaries?.first.debugDescription))")
                self.InitialRingData = summaries?.first
            }
        }

        healthStore.execute(query)
    }
    
    func resetWorkout() {
        builder = nil
        workout = nil
        session = nil
        activeEnergy = 0
        averageHeartRate = 0
        heartRate = 0
    }
}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            self.running = toState == .running
        }
        
        // Wait for the session to transition states before ending the builder.
        if toState == .ended {
            builder?.endCollection(withEnd: date) { (success, error) in
                self.builder?.finishWorkout { (workout, error) in
                    DispatchQueue.main.async {
                        self.workout = workout
                        self.started = false
                    }
                }
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                return // Nothing to do.
            }
            
            let statistics = workoutBuilder.statistics(for: quantityType)
            
            // Update the published values.
            updateForStatistics(statistics)
        }
    }
}

