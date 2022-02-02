//
//  CommunicationManager.swift
//  WorkingWatch WatchKit Extension
//
//  Created by Olivier Wittop Koning on 23/01/2022.
//

import Foundation
import WatchConnectivity

extension WorkoutManager {
    
    func sendMessage(message: HealthData) -> Void {
        guard WCSession.default.activationState == .activated else {
            print("Session not active")
            return
        }
        print("Message to be send to the iphone: \(message)")
        if lastSendData == message {
            print("The data is the same so not sending it")
            return
        } else {
            print("sending message to iphone with data: \(message), because it isn't the same")
            
            WCSession.default.sendMessage(message.msg, replyHandler: { replyMessage in
                print("Recieved a message from the watch: \(replyMessage)")
            }, errorHandler: { error in
                print("There was an erorr while send a message: \(error.localizedDescription)")
            })
            lastSendData = message
        }
    }
}

struct HealthData: CustomStringConvertible, Equatable {
    var kcals: Double
    var mins: Int
    var heartRate: Double
    
    var msg: [String: Any] {
        return ["kcals": kcals, "heartRate": heartRate, "mins": mins]
    }
    var description: String {
        return "{\"kcals\": \(kcals), \"heartRate\": \(heartRate), \"mins\": \(mins)}"
    }
    
    
}
