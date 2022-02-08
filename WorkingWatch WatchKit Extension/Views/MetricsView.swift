//
//  MetricsView.swift
//  WorkingWatch WatchKit Extension
//
//  Created by Olivier Wittop Koning on 23/01/2022.
//

import SwiftUI
import HealthKit

struct MetricsView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    
    var body: some View {
        TimelineView(MetricsTimelineSchedule(from: workoutManager.builder?.startDate ?? Date())) { context in
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    ProgressView(value: workoutManager.progrezz) {
                        Image(systemName: "figure.walk")
                            .padding()
                            .font(.title3)
                    }.gaugeStyle(.circular)
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.darkRed))
                        .padding(.top)
                    Spacer()
                    ElapsedTimeView(elapsedTime: workoutManager.builder?.elapsedTime ?? 0, showSubseconds: context.cadence == .live)
                        .foregroundStyle(.yellow)
                    Text(Measurement(value: workoutManager.activeEnergy, unit: UnitEnergy.kilocalories)
                            .formatted(.measurement(width: .abbreviated, usage: .workout, numberFormatStyle: .number.precision(.fractionLength(0)))))
                    Text(workoutManager.heartRate.formatted(.number.precision(.fractionLength(0))) + " bpm")
                }
            }
            .font(.system(.title2, design: .rounded).monospacedDigit().lowercaseSmallCaps())
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

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

struct MetricsView_Previews: PreviewProvider {
    static var wm = WorkoutManager()
    static var previews: some View {
        MetricsView().environmentObject(wm).onAppear {
            wm.activeEnergy = 245
            wm.heartRate = 133
        }
    }
}

private struct MetricsTimelineSchedule: TimelineSchedule {
    var startDate: Date
    
    init(from startDate: Date) {
        self.startDate = startDate
    }
    
    func entries(from startDate: Date, mode: TimelineScheduleMode) -> PeriodicTimelineSchedule.Entries {
        PeriodicTimelineSchedule(from: self.startDate, by: (mode == .lowFrequency ? 1.0 : 1.0 / 30.0))
            .entries(from: startDate, mode: mode)
    }
}


struct ElapsedTimeView: View {
    var elapsedTime: TimeInterval = 0
    var showSubseconds: Bool = true
    @State private var timeFormatter = ElapsedTimeFormatter()
    
    var body: some View {
        Text(NSNumber(value: elapsedTime), formatter: timeFormatter)
            .fontWeight(.semibold)
            .onChange(of: showSubseconds) {
                timeFormatter.showSubseconds = $0
            }
    }
}

class ElapsedTimeFormatter: Formatter {
    let componentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    var showSubseconds = true
    
    override func string(for value: Any?) -> String? {
        guard let time = value as? TimeInterval else {
            return nil
        }
        
        guard let formattedString = componentsFormatter.string(from: time) else {
            return nil
        }
        
        if showSubseconds {
            let hundredths = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
            let decimalSeparator = Locale.current.decimalSeparator ?? "."
            return String(format: "%@%@%0.2d", formattedString, decimalSeparator, hundredths)
        }
        
        return formattedString
    }
}
