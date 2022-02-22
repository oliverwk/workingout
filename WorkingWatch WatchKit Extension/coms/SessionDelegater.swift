//
//  SessionDelegater.swift
//  WorkingWatch WatchKit Extension
//
//  Created by Olivier Wittop Koning on 23/01/2022.
//

import Foundation
import WatchConnectivity
import os

#if os(watchOS)
import ClockKit
#endif
class SessionDelegater: NSObject, WCSessionDelegate {
    let logger = Logger(
        subsystem: "nl.wittopkoning.WorkingWatch",
        category: "SessionDelegater"
    )
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        logger.log("activationDidCompleteWith: \(activationState.rawValue, privacy: .public)")
    }
    
    
    // Called when WCSession reachability is changed.
    //
    func sessionReachabilityDidChange(_ session: WCSession) {
        logger.log("sessionReachabilityDidChange")
    }
    
    
    // Called when a message is received and the peer doesn't need a response.
    //
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        logger.log("didReceiveMessage: \(message.debugDescription, privacy: .public)")
    }
    
    // Called when a message is received and the peer needs a response.
    //
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        self.session(session, didReceiveMessage: message)
        replyHandler(["time": Date().timeIntervalSinceNow]) // Echo back the time stamp.
    }
    
}
