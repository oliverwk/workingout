//
//  ContentView.swift
//  Shared
//
//  Created by Olivier Wittop Koning on 23/01/2022.
//

import SwiftUI

struct ContentView: View {
    
    let minutes: [String: Int] = ["WorkoutVideo-1.mp4": 40, "WorkoutVideo-2.mp4": 45, "WorkoutVideo-3.mp4": 33, "WorkoutVideo-4.mp4": 35, "WorkoutVideo-5.mp4": 35, "WorkoutVideo-6.mp4": 34]
    let videos = ["WorkoutVideo-1.mp4","WorkoutVideo-2.mp4","WorkoutVideo-3.mp4","WorkoutVideo-4.mp4","WorkoutVideo-5.mp4","WorkoutVideo-6.mp4"]
    
    @EnvironmentObject var externalDisplayContent: ExternalDisplayContent

    var body: some View {
        NavigationView {
            List {
                ForEach(self.videos, id: \.self) { video in
                    NavigationLink(destination: VideoView(video: Bundle.main.url(forResource: "Videos/\(video.split(separator: ".")[0])", withExtension: "mp4")!, title: URL(fileURLWithPath: video).lastPathComponent).environmentObject(externalDisplayContent)) {
                        HStack {
                            Text("\(URL(fileURLWithPath: video).lastPathComponent)")
                            Spacer()
                            Text("\(minutes[video] ?? 25) min")
                                .foregroundColor(.green)
                        }
                    }
                }.navigationTitle(Text("Workouts"))
                NavigationLink("Zeilen") {
                    ZeilView()
                }
                NavigationLink("Snelheid") {
                    SpeedView()
                }
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
