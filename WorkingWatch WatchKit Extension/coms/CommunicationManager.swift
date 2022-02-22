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
            logger.log("Session not active")
            return
        }
        logger.log("Message to be send to the iphone: \(message, privacy: .public)")
        if lastSendData == message {
            logger.log("The data is the same so not sending it")
            return
        } else {
            logger.log("sending message to iphone with data: \(message, privacy: .public), because it isn't the same")
            
            WCSession.default.sendMessage(message.msg, replyHandler: { replyMessage in
                self.logger.log("Recieved a message from the watch: \(replyMessage, privacy: .public)")
            }, errorHandler: { error in
                self.logger.log("There was an erorr while send a message: \(error.localizedDescription, privacy: .public)")
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
