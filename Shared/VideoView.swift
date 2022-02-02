//
//  VideoView.swift
//  WorkingOut
//
//  Created by Olivier Wittop Koning on 23/01/2022.
//

import SwiftUI
import AVKit

struct VideoView: View {
    @StateObject var ringManager = RingManager()
    @State var barHidden = false
    let video: URL
    var player: AVPlayer
    var colors: [Color] = [Color.darkRed, Color.lightRed]
    
    init (video: URL) {
        self.video = video
        player = AVPlayer(url: video.absoluteURL)
        player.volume = 0
        
    }
    
    
    var body: some View {
        VStack {
            VideoPlayer(player: player) {
                VStack(alignment: .trailing) {
                    HStack(alignment: .bottom) {
                        ActivityView().environmentObject(ringManager)
                        Spacer()
                        ActivityRingViewHealthKit(activitySummary: ringManager.HeahtlKitSummary())
                            .frame(width: 100, height: 100, alignment: .center)
                            .edgesIgnoringSafeArea(.all)
                            .offset(y: -40)
                        
                        /*ZStack {
                         //ActivityRingView(progress: $ringManager.kcal, colors: [Color.darkRed, Color.lightRed, Color.outlineRed], RingSize: 100, fullRing: 600.0).fixedSize()
                         
                         /*ActivityRingView(progress: $ringManager.KcalForRing, colors: [Color.darkRed, Color.lightRed, Color.outlineRed], RingSize: 100, fullRing: 600.0).fixedSize()
                          ActivityRingView(progress: $ringManager.mins, colors: [Color.darkGreen, Color.lightGreen, Color.outlineGreen], RingSize: 62, fullRing: 30.0).fixedSize().padding().padding()*/
                         }.background(.thinMaterial).cornerRadius(90).padding().padding()*/
                    }
                    Spacer()
                }
            }.onTapGesture {
                if player.isPlaying {
                    player.pause()
                    print("player paused")
                    ringManager.started = false
                    ringManager.timer.connect().cancel()
                    self.barHidden = false
                } else {
                    player.play()
                    if ringManager.startedDate == nil {
                        ringManager.startedDate = Date()
                    }
                    print("player resumed")
                    ringManager.started = true
                    self.barHidden = true
                    ringManager.timer = Timer.publish(every: 1, on: .main, in: .common)
                    let canc = ringManager.timer.connect()
                    print("canc: \(canc)")
                    $ringManager.cancelTimer.wrappedValue = canc
                }
            }
        }.navigationTitle(Text(video.lastPathComponent)).navigationBarHidden(barHidden)
    }
}


struct VideoView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            VideoView(video: Bundle.main.url(forResource: "Videos/WorkoutVideo-1", withExtension: "mp4")!)
                .previewInterfaceOrientation(.landscapeRight)
                .previewDevice("iPad (9th generation)")
            VideoView(video: Bundle.main.url(forResource: "Videos/WorkoutVideo-1", withExtension: "mp4")!)
                .previewInterfaceOrientation(.landscapeRight)
                .previewDevice("iPhone 7")
        }
    }
}

extension AVPlayer {
    var isPlaying: Bool {
        return rate != 0 && error == nil
    }
}
