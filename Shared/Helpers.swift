//
//  Helpers.swift
//  WorkingOut
//
//  Created by Olivier Wittop Koning on 02/02/2022.
//

import Foundation
import SwiftUI

extension Color {
    public static var outlineRed: Color {
        return Color(decimalRed: 34, green: 0, blue: 3)
    }
    public static var darkRed: Color {
        return Color(decimalRed: 221, green: 31, blue: 59)
    }
    public static var lightRed: Color {
        return Color(decimalRed: 239, green: 54, blue: 128)
    }
    
    public static var outlineGreen: Color {
        return Color(decimalRed: 0, green: 36, blue: 3)
    }
    public static var darkGreen: Color {
        return Color(decimalRed: 31, green: 221, blue: 59)
    }
    public static var lightGreen: Color {
        return Color(decimalRed: 128, green: 255, blue: 0)
    }
    
    public init(decimalRed red: Double, green: Double, blue: Double) {
        self.init(red: red / 255, green: green / 255, blue: blue / 255)
    }
}

extension Date {
    var today: Date? {
        let calendar = Calendar.current
        
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)
        
        components.hour = 1
        components.minute = 0
        components.second = 0
        
        return calendar.date(from: components)
    }
}

