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
    @EnvironmentObject var externalDisplayContent: ExternalDisplayContent
    
    let video: URL
    var player: AVPlayer
    var colors: [Color] = [Color.darkRed, Color.lightRed]
    var ViewIsExternalScreen: Bool
    
    init (video: URL, title: String, ViewIsExternalScreen: Bool = false) {
        self.video = video
        player = AVPlayer(url: video.absoluteURL)
        self.ViewIsExternalScreen = ViewIsExternalScreen
        self.barTitle = title
        player.volume = 0
    }
    
    var body: some View {
        VStack {
            if (externalDisplayContent.isShowingOnExternalDisplay && ViewIsExternalScreen) || !externalDisplayContent.isShowingOnExternalDisplay {
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
                }
                .onTapGesture {
                    if !ViewIsExternalScreen {
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
                }
                
            } else {
                VStack {
                    ActivityView(BarHidden: $barHidden).environmentObject(ringManager)
                        .offset(y: ($barHidden.wrappedValue ? -25 : 0))
                    Text("Je hebt nog \((600-ringManager.kcal).rounded(), format: .number) cal te gaan").padding()
                    HStack {
                        Button {
                            let newtime = CMTimeGetSeconds((externalDisplayContent.player!.currentTime())) - 15
                            if newtime < (CMTimeGetSeconds(externalDisplayContent.player!.currentItem!.duration) + 15) {
                                externalDisplayContent.player?.seek(to: CMTimeMake(value: Int64(newtime*1000), timescale: 1000))
                                logger.log("seeking to \(newtime.debugDescription)")
                            } else {
                                logger.log("\((CMTimeGetSeconds(externalDisplayContent.player!.currentItem!.duration) + 15)) is niet groter dan \(newtime)")
                            }
                        } label: {
                            Image(systemName: "gobackward.15")
                        }.padding()
                        
                        Button {
                            if !(externalDisplayContent.player!.isPlaying) {
                                externalDisplayContent.player?.play()
                                logger.log("Playing \(externalDisplayContent.videoFile)")
                            } else if externalDisplayContent.player!.isPlaying {
                                externalDisplayContent.player?.pause()
                                logger.log("pause \(externalDisplayContent.videoFile)")
                            }
                            
                        } label: {
                            Image(systemName: "play")
                        }.padding()
                        
                        Button {
                            let newtime = CMTimeGetSeconds((externalDisplayContent.player!.currentTime())) + 15
                            if newtime < (CMTimeGetSeconds(externalDisplayContent.player!.currentItem!.duration) - 15) {
                                externalDisplayContent.player?.seek(to: CMTimeMake(value: Int64(newtime*1000), timescale: 1000))
                                logger.log("seeking to \(newtime.debugDescription)")
                            } else {
                                logger.log("\((CMTimeGetSeconds(externalDisplayContent.player!.currentItem!.duration) - 15)) is niet groter dan \(newtime)")
                            }
                        } label: {
                            Image(systemName: "goforward.15")
                        }.padding()
                        
                    }
                }
            }
        }.navigationTitle(barTitle ?? "")
            .navigationBarBackButtonHidden($barHidden.wrappedValue)
            .navigationBarHidden($barHidden.wrappedValue)
            .navigationBarTitleDisplayMode(.inline)
            .edgesIgnoringSafeArea([($barHidden.wrappedValue ? .top : .bottom)])
            .onAppear {
                logger.log("externalDisplayContent: \(externalDisplayContent.debugDescription) View: \(ViewIsExternalScreen)")
                if !ViewIsExternalScreen && externalDisplayContent.isShowingOnExternalDisplay {
                    externalDisplayContent.videoFile = self.video.lastPathComponent
                    logger.log("setting the videoFile to: \(self.video.lastPathComponent)")
                    externalDisplayContent.player?.replaceCurrentItem(with: AVPlayerItem(url: self.video))
                }
                
                if ViewIsExternalScreen && externalDisplayContent.isShowingOnExternalDisplay {
                    externalDisplayContent.player = player
                }
            }
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
