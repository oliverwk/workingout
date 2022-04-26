//
//  WorkingOutApp.swift
//  Shared
//
//  Created by Olivier Wittop Koning on 23/01/2022.
//

import SwiftUI
import Combine
import AVFoundation

@main
struct WorkingOutApp: App {
    @ObservedObject var externalDisplayContent = ExternalDisplayContent()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(externalDisplayContent)
                .onReceive(
                    screenDidConnectPublisher,
                    perform: screenDidConnect
                )
                .onReceive(
                    screenDidDisconnectPublisher,
                    perform: screenDidDisconnect
                )
        }
    }
    
    @State var additionalWindows: [UIWindow] = []

    private var screenDidConnectPublisher: AnyPublisher<UIScreen, Never> {
        NotificationCenter.default
            .publisher(for: UIScreen.didConnectNotification)
            .compactMap { $0.object as? UIScreen }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    private var screenDidDisconnectPublisher: AnyPublisher<UIScreen, Never> {
        NotificationCenter.default
            .publisher(for: UIScreen.didDisconnectNotification)
            .compactMap { $0.object as? UIScreen }
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
    
    private func screenDidConnect(_ screen: UIScreen) {
        let window = UIWindow(frame: screen.bounds)

        window.windowScene = UIApplication.shared.connectedScenes
            .first { ($0 as? UIWindowScene)?.screen == screen }
            as? UIWindowScene

        let view = VideoView(video: Bundle.main.url(forResource: "Videos/\(externalDisplayContent.videoFile.split(separator: ".")[0])", withExtension: "mp4")!, title: externalDisplayContent.videoFile, ViewIsExternalScreen: true)
            .environmentObject(externalDisplayContent)
        let controller = UIHostingController(rootView: view)
        window.rootViewController = controller
        window.isHidden = false
        additionalWindows.append(window)
        externalDisplayContent.isShowingOnExternalDisplay = true
    }

    private func screenDidDisconnect(_ screen: UIScreen) {
        additionalWindows.removeAll { $0.screen == screen }
    }
}

class ExternalDisplayContent: ObservableObject, CustomDebugStringConvertible {
    @Published var videoFile = "annasVideo.mp4"
    @Published var isShowingOnExternalDisplay = false
    @Published var player: AVPlayer?
    var debugDescription: String {
        return "videoFile: \(videoFile), isShowingOnExternalDisplay: \(isShowingOnExternalDisplay) player: \(player.debugDescription)"
    }
}
