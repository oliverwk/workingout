//
//  Dagdeel.swift
//  WorkingOut (iOS)
//
//  Created by Olivier Wittop Koning on 14/07/2022.
//

import Foundation
import HealthKit

class DagDeelInfo: ObservableObject {
    @Published var activiteit: Activiteit
    @Published var tijdRange: [Date]
    @Published var onweerEnRegen = false
    @Published var AfstandAfgelegd = 0.0
    @Published var opmerkingenHealthkitNotes = "Het was een beetje kut"
    var WKtype: HKWorkoutActivityType {
        switch(activiteit) {
        case .other:
            return .other
        case .zeilen:
            return .sailing
        case .zwemmen:
            return .waterSports
        case .kaarten:
            return .other
        case .halfZeilen_halfKaarten:
            return .sailing
        }
    }
    var timeSpenSailing: Double {
        (tijdRange[1]-tijdRange[0])/60
    }
    
    var CalsBurendPerMinute: Double {
        switch(activiteit) {
        case .other:
            return 1.5
        case .zeilen:
            return (20/3) // ongeveer 6,6 cals per minute, dus 400 per uur
        case .zwemmen:
            return 3.716666666 // 223 per uur
        case .kaarten:
            return 2.2 // 132 per uur
        case .halfZeilen_halfKaarten:
            return 4.433333333 // 66 per half uur en 200 per half uur
        }
    }
    
    var calsIsCustom = false
    var calsCustom = 0.0
    var Cals: Double {
        set {
            calsCustom = newValue
        }
        get {
            if calsIsCustom {
                return calsCustom
            } else {
                    return timeSpenSailing*CalsBurendPerMinute
            }
        }
    }
    
    init(_ dagDeel: DagDeel) {
        activiteit = .other
       
        if (dagDeel == .ochtend) {
            tijdRange = [Date(.ochtend), Date(.middag)]
        } else if (dagDeel == .middag) {
            tijdRange = [Date(.middag), Date(.avondEtenTijd)]
        } else if (dagDeel == .SpelTijd) {
            tijdRange = [Date(.SpelTijd), Date(.nacht)]
        } else {
            tijdRange = [Date(), Date()]
        }
        Cals = 0.0
    }
}

enum Activiteit {
    case zeilen
    case kaarten
    case zwemmen
    case halfZeilen_halfKaarten
    case other
}

enum DagDeel {
    case ochtend, middag, avondEtenTijd, SpelTijd, nacht
}

extension Date {
    init(_ dagDeel: DagDeel) {
        var dateInfo = DateComponents()
        dateInfo.day =  Calendar.current.component(.day, from: Date()) // mebay add some things to change the day 
        dateInfo.month = Calendar.current.component(.month, from: Date())
        dateInfo.year = Calendar.current.component(.year, from: Date())
        
        if (dagDeel == .ochtend) {
            dateInfo.hour = 9
            dateInfo.minute = 30
            self.init(timeIntervalSince1970: Calendar.current.date(from: dateInfo)!.timeIntervalSince1970)
        } else if (dagDeel == .middag) {
            dateInfo.hour = 12
            dateInfo.minute = 30
            self.init(timeIntervalSince1970: Calendar.current.date(from: dateInfo)!.timeIntervalSince1970)
        } else if (dagDeel == .avondEtenTijd) {
            dateInfo.hour = 17
            dateInfo.minute = 0
            self.init(timeIntervalSince1970: Calendar.current.date(from: dateInfo)!.timeIntervalSince1970)
        } else if (dagDeel == .SpelTijd) {
            dateInfo.hour = 18
            dateInfo.minute = 30
            self.init(timeIntervalSince1970: Calendar.current.date(from: dateInfo)!.timeIntervalSince1970)
        } else if (dagDeel == .nacht) {
            dateInfo.hour = 23
            dateInfo.minute = 0
            self.init(timeIntervalSince1970: Calendar.current.date(from: dateInfo)!.timeIntervalSince1970)
        } else {
            self.init()
        }
    }
    
    static func - (lhs: Date, rhs: Date) -> TimeInterval {
        return lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate
    }
}
