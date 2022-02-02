//
//  ActivityRingView.swift
//  WorkingOut
//
//  Created by Olivier Wittop Koning on 23/01/2022.
//

import SwiftUI
import HealthKitUI



@available(*, unavailable, message: "use the other one")
struct ActivityRingView: View {
    @Binding var progress: CGFloat
    let colors: [Color] // = [Color.darkRed, Color.lightRed, Color.outlineRed]
    let RingSize: Double
    let fullRing: Double
  
   
    var body: some View {
        withAnimation(.spring(response: 0.6, dampingFraction: 1.0, blendDuration: 1.0)) {
            ZStack {
                Circle()
                    .stroke(colors[2], lineWidth: 15)
                Circle()
                    .trim(from: 0, to: ((progress-(progress > fullRing ? fullRing : 0))/fullRing))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: colors),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 15, lineCap: .round)
                    ).rotationEffect(.degrees(-90))
                Circle()
                    .frame(width: 15, height: 15)
                    .foregroundColor(colors[0])
                    .offset(y: -1*RingSize/2)
                Circle()
                    .frame(width: 15, height: 15)
                    .foregroundColor(progress > 0.95 ? colors[1]: colors[1].opacity(0))
                    .offset(y: -1*RingSize/2)
                    .rotationEffect(Angle.degrees(360 * Double((progress-(progress > fullRing ? fullRing : 0))/fullRing)))
                    .shadow(color: Double((progress-(progress > fullRing ? fullRing : 0))/fullRing) > 0.96 ? Color.black.opacity(0.1): Color.clear, radius: 3, x: 4, y: 0)
            }.frame(idealWidth: RingSize, idealHeight: RingSize, alignment: .center).background(.white)
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

@available(*, unavailable, message: "use the other one")
struct ActivityRingView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ActivityRingView(progress: .constant(500), colors: [Color.darkRed, Color.lightRed, Color.outlineRed], RingSize: 100, fullRing: 600.0).fixedSize().padding()
            ActivityRingView(progress: .constant(15.0), colors: [Color.darkGreen, Color.lightGreen, Color.outlineGreen], RingSize: 62, fullRing: 30.0).fixedSize()
        }.preferredColorScheme(.dark)
    }
}
