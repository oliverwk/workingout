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
    var t = RepeatingTimer(timeInterval: 30)
    
    @State var barHidden = false
    @State var barTitle: String? = ""
    @EnvironmentObject var externalDisplayContent: ExternalDisplayContent
    
    let video: URL
    var player: AVPlayer
    var colors: [Color] = [Color.darkRed, Color.lightRed]
    var ViewIsExternalScreen: Bool
    var timeObserverToken: Any?
    @State var OldPlayState = false
    @State var showSkipbutton = false
    
    
    init (video: URL, title: String, ViewIsExternalScreen: Bool = false) {
        self.video = video
        player = AVPlayer(url: video.absoluteURL)
        self.ViewIsExternalScreen = ViewIsExternalScreen
        self.barTitle = title
        player.volume = 0
        player.externalPlaybackVideoGravity = .resizeAspectFill
        
        player.currentItem?.externalMetadata = AddVideoMetaData()
//        player.speeds = []
    }
    
    func AddVideoMetaData() -> [AVMutableMetadataItem] {
        let titleItem = AVMutableMetadataItem()
        titleItem.identifier = .commonIdentifierTitle
        titleItem.value = "WorkingOut \((self.barTitle == "annasVideo.mp4" ? "annasVideo    .mp4" :  self.barTitle!).prefix(14))" as NSString
        
        let subtitleItem = AVMutableMetadataItem()
        subtitleItem.identifier = .iTunesMetadataTrackSubTitle
        subtitleItem.value = "GrowingAnnanas" as NSString

        let creatorItem = AVMutableMetadataItem()
        subtitleItem.identifier = .commonIdentifierCreator
        subtitleItem.value = "GrowingAnnanas" as NSString

        let langueageItem = AVMutableMetadataItem()
        subtitleItem.identifier = .commonIdentifierLanguage
        subtitleItem.value = "English" as NSString
        
        let infoItem = AVMutableMetadataItem()
        infoItem.identifier = .commonIdentifierDescription
        infoItem.value = "In deze video van (zo alng duurt hij) minuten gaat anna een HIIT workout doen. High Intensity Interval Training. Dit is goed voor je gezondheid en ringen" as NSString // Descriptive info paragraph
        
        return [titleItem, subtitleItem, creatorItem, langueageItem, infoItem]
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
                                .frame(width: 70, height: 70, alignment: .center)
                                .edgesIgnoringSafeArea(.all)
                                .offset(y: -95)
                                .padding(.vertical, 20)
                        }
                        Spacer()
                    }
                }.ignoresSafeArea(SafeAreaRegions.all, edges: .horizontal).ignoresSafeArea(SafeAreaRegions.all, edges: .bottom).overlay {
                    HStack {
                        Spacer()
                        Button {
                            print("skipping forward")
                            let newtime = CMTimeGetSeconds((player.currentTime())) + 55
                            if newtime < (CMTimeGetSeconds(player.currentItem!.duration) - 55) {
                                player.seek(to: CMTimeMake(value: Int64(newtime*1000), timescale: 1000))
                                logger.log("seeking to \(newtime.debugDescription)")
                            } else {
                                logger.log("\((CMTimeGetSeconds(player.currentItem!.duration) - 55)) is niet groter dan \(newtime)")
                            }
                        } label: {
                            Image(systemName: "goforward")
                        }
                        .foregroundColor(.black)
                        .padding()
                        .background(.white)
                        .cornerRadius(40)
                        .padding()
                        .opacity(showSkipbutton ? 1 : 0)
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
                t.eventHandler = {
                    logger.log("Timer Fired, time to check for new health data")
                    Task(priority: .medium) {
                        await ringManager.GetHealthData()
                    }
                }
            }
            .onAppear {
                logger.log("externalDisplayContent: \(externalDisplayContent.debugDescription) View: \(ViewIsExternalScreen)")
                if !ViewIsExternalScreen && externalDisplayContent.isShowingOnExternalDisplay {
                    externalDisplayContent.videoFile = self.video.lastPathComponent
                    logger.log("setting the videoFile to: \(self.video.lastPathComponent)")
                    externalDisplayContent.player?.replaceCurrentItem(with: AVPlayerItem(url: self.video))
                }
                if !externalDisplayContent.isShowingOnExternalDisplay {
                    self.barTitle = self.video.lastPathComponent
                    var currentTime = CMTime.zero
                    var times = [NSValue]()
                    
                    // if is first thing. Add 15 seconds info
                    var interval = 50
                    var beginTime = 15
                    
                    switch self.barTitle {
                    case "WorkoutVideo-1.mp4":
                        beginTime = 5
                        interval = 60
                    case "WorkoutVideo-2.mp4":
                        beginTime = 285
                        interval = 60
                    case "WorkoutVideo-3.mp4":
                        beginTime = 270
                        interval = 50
                    case "WorkoutVideo-4.mp4":
                        beginTime = 336
                        interval = 50
                    case "WorkoutVideo-5.mp4":
                        beginTime = 336
                        interval = 50
                    case "WorkoutVideo-6.mp4":
                        beginTime = 295
                        interval = 50
                    default:
                        interval = 1000
                        beginTime = Int(CMTimeGetSeconds(player.currentItem?.duration ?? CMTime.zero))
                    }
                    
                    currentTime = currentTime + CMTime(value: CMTimeValue(beginTime), timescale: currentTime.timescale)
                    
                    // Calculate boundary times
                    while currentTime < self.player.currentItem!.duration {
                        currentTime = currentTime + CMTime(value: CMTimeValue(interval), timescale: currentTime.timescale)
                        print("currentTime: \(currentTime)")
                        times.append(NSValue(time:currentTime))
                    }
                    
                    
                    player.addBoundaryTimeObserver(forTimes: times, queue: .main) {
                        print("add skip button for 10 seconds every 50 seconds")
                        showSkipbutton = true
                        // Wait ten seconds to not show it
                        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                            showSkipbutton = false
                        }
                    }
                    
                    let timeScale = CMTimeScale(NSEC_PER_SEC)
                    let time = CMTime(seconds: 0.5, preferredTimescale: timeScale)
                    
                    player.addPeriodicTimeObserver(forInterval: time, queue: .main) { time in
                        // update player transport UI
                        if OldPlayState != player.isPlaying {
                            self.OldPlayState = player.isPlaying
                            if player.isPlaying {
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
                            } else {
                                logger.log("player paused")
                                ringManager.started = false
                                ringManager.timer.connect().cancel()
                                self.barHidden = false
                                self.barTitle = self.video.lastPathComponent
                            }
                        }
                    }
                }
                
                if ViewIsExternalScreen && externalDisplayContent.isShowingOnExternalDisplay {
                    externalDisplayContent.player = player
                }
                
            }
    }
}


struct VideoView_Previews: PreviewProvider {
    static let externalDisplayContent = ExternalDisplayContent()
    static var previews: some View {
        Group {
            VideoView(video: Bundle.main.url(forResource: "Videos/WorkoutVideo-1", withExtension: "mp4")!, title: "WorkoutVideo-1.mp4", ViewIsExternalScreen: true)
                .environmentObject(externalDisplayContent)
                .previewInterfaceOrientation(.landscapeRight)
                .previewDevice("iPad (9th generation)")
                .onAppear {
                    externalDisplayContent.isShowingOnExternalDisplay = true
                }
            
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
