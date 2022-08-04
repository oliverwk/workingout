//
//  SpeedView.swift
//  WorkingOut
//
//  Created by Olivier Wittop Koning on 03/08/2022.
//

import SwiftUI
import CoreLocation
import os.log

class SpeedManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    let logger = Logger(
        subsystem: "nl.wittopkoning.WorkingOut",
        category: "SpeedManager"
    )
    
    let manager = CLLocationManager()
    @Published var CurrentSpeed: Double = 0.0
    var currentSpeed: String {
        get {
            if (CurrentSpeed > 0.0 && manager.location?.speedAccuracy ?? 1000 < 5) {
                return CurrentSpeed.formatted(.number.precision(.fractionLength(1)))
            } else {
                    return "0,0"
            }
        }
    }
    
    override init() {
        super.init()
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        logger.log("speed: \((manager.location?.speed ?? 0.0), privacy: .public)")
        logger.log("with an accuracy of: \((manager.location?.speedAccuracy ?? 0.0), privacy: .public)")
        CurrentSpeed = (manager.location?.speed ?? 0.0) * 3.6
    }
    
    private func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Error: \(error.localizedDescription)")
    }
}

struct SpeedView: View {
    
    @StateObject var manager = SpeedManager()
    var currentSpeed = 0.0
    
    var body: some View {
        VStack {
            Text("You'r driving at \(manager.currentSpeed) km/h")
        }.onAppear {
            manager.manager.requestWhenInUseAuthorization()
            manager.manager.startUpdatingLocation()
        }.onDisappear {
            manager.manager.stopUpdatingLocation()
        }
    }
}

struct SpeedView_Previews: PreviewProvider {
    static var previews: some View {
        SpeedView()
    }
}
