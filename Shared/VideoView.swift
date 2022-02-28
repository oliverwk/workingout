//
//  VideoView.swift
//  WorkingOut
//
//  Created by Olivier Wittop Koning on 23/01/2022.
//

import SwiftUI
import AVKit
import os

struct VideoView: View {
    let logger = Logger(
        subsystem: "nl.wittopkoning.WorkingOut",
        category: "VideoView"
    )
    @StateObject var ringManager = RingManager()
    @State var barHidden = false
    @State var barTitle: String? = ""
    
    let video: URL
    var player: AVPlayer
    var colors: [Color] = [Color.darkRed, Color.lightRed]
    
    init (video: URL, title: String) {
        self.video = video
        player = AVPlayer(url: video.absoluteURL)
        self.barTitle = title
        player.volume = 0
    }
    
    
    var body: some View {
        VStack {
            VideoPlayer(player: player) {
                VStack(alignment: .trailing) {
                    HStack(alignment: .bottom) {
                        ActivityView(BarHidden: $barHidden).environmentObject(ringManager)
                            .offset(y: ($barHidden.wrappedValue ? -25 : 0))
                        Spacer()
                        ActivityRingViewHealthKit(activitySummary: ringManager.HeahtlKitSummary())
                            .frame(width: 80, height: 80, alignment: .center)
                            .edgesIgnoringSafeArea(.all)
                            .offset(y: ($barHidden.wrappedValue ? -90 : -50))
                            .padding()
                    }
                    Spacer()
                }
            }.onTapGesture {
                if player.isPlaying {
                    player.pause()
                    logger.log("player paused")
                    ringManager.started = false
                    ringManager.timer.connect().cancel()
                    self.barHidden = false
                    self.barTitle = self.video.lastPathComponent
                } else {
                    player.play()
                    if ringManager.startedDate == nil {
                        ringManager.startedDate = Date()
                    }
                    logger.log("player resumed")
                    ringManager.started = true
                    self.barHidden = true
                    self.barTitle = ""
                    ringManager.timer = Timer.publish(every: 1, on: .main, in: .common)
                    let canc = ringManager.timer.connect()
                    print("canc: \(canc)")
                    $ringManager.cancelTimer.wrappedValue = canc
                }
            }
        }.navigationTitle(barTitle ?? "")
            .navigationBarBackButtonHidden($barHidden.wrappedValue)
            .navigationBarHidden($barHidden.wrappedValue)
            .navigationBarTitleDisplayMode(.inline)
            .edgesIgnoringSafeArea([($barHidden.wrappedValue ? .top : .bottom)])
    }
}


struct VideoView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            
            /*VideoView(video: Bundle.main.url(forResource: "Videos/WorkoutVideo-1", withExtension: "mp4")!, title: "WorkoutVideo-1.mp4")
             .previewInterfaceOrientation(.landscapeRight)
             .previewDevice("iPad (9th generation)")*/
             
            VideoView(video: Bundle.main.url(forResource: "Videos/WorkoutVideo-1", withExtension: "mp4")!, title: "WorkoutVideo-1.mp4")
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
