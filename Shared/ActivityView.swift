//
//  ActivityView.swift
//  WorkingOut
//
//  Created by Olivier Wittop Koning on 23/01/2022.
//

import SwiftUI

struct ActivityView: View {
    @EnvironmentObject var ringManager: RingManager
    var formatter: DateComponentsFormatter {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.unitsStyle = .positional
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }
    
    @State var isAtMaxScale = false
    private let animation = Animation.easeInOut(duration: 1).repeatForever(autoreverses: true)
    private let maxScale: CGFloat = 1.2
    @Binding var BarHidden: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(formatter.string(from: TimeInterval((ringManager.currentDate.timeIntervalSince1970-(ringManager.startedDate?.timeIntervalSince1970 ?? Date().timeIntervalSince1970))))!)")
                .font(.largeTitle)
                .foregroundColor(.yellow)
                .onReceive(ringManager.timer) { input in
                    ringManager.currentDate = input
                }
            HStack {
                Text("\(ringManager.heartRate.formatted(.number.precision(.fractionLength(0))))")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.title2)
                    .scaleEffect(isAtMaxScale ? maxScale : 1)
                    .onReceive(ringManager.timer) { _ in
                        withAnimation(self.animation, {
                            self.isAtMaxScale.toggle()
                        })
                    }
            }
            HStack {
                Text("\(ringManager.kcal.rounded(), format: .number)")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                Text("CAL")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(decimalRed: 230.0, green: 55.0, blue: 84.0))
            }
        }   .padding()
            .background(.thinMaterial)
            .cornerRadius(16)
            .padding()
//            .padding(.all, ($BarHidden.wrappedValue ? 0 : nil))
    }
}

struct ActivityView_Previews: PreviewProvider {
    static var ringManagers = RingManager()
    static var previews: some View {
        ActivityView(BarHidden: .constant(false)).preferredColorScheme(.dark)
            .environmentObject(ringManagers)
            .onAppear {
                ringManagers.kcal = 50
                ringManagers.heartRate = 133
                ringManagers.currentDate = Date(timeIntervalSince1970: Date().timeIntervalSince1970+32)
            }
    }
}
