//
//  IndoorDirectionView.swift
//

import SwiftUI

struct IndoorDirectionView: View {
    @ObservedObject var jmapManager = JMapManager.shared
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        let floors: [JMapFloor] = jmapManager.floors()
        ZStack{
            VStack{
                Spacer().frame(height: ScreenSize.safeTop())
                /// Topbar for Directions
                VStack(spacing:0){
                    /// Primary Info
                    HStack{
                        ZStack{
                            HStack{
                                Spacer()
                                Text(jmapManager.pubSelectedFloor?.name ?? "")
                                    .font(.title2)
                                    .bold()
                                    .fixedSize(horizontal: false, vertical: true)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .zIndex(0)
                            HStack{
                                Spacer()
                                Button {
                                    jmapManager.pubPresentDirectionPanel = false
                                    jmapManager.clearDrawing()
                                    jmapManager.stopIndoorSimulator()
                                    jmapManager.pubIsActiveIndoorNavigation = false
                                    NotificationManager.shared.cancelRunningNotification()
                                } label: {
                                    Image(systemName: "multiply")
                                        .resizable()
                                        .frame(width:25, height:25)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                }.padding(10)
                            }.zIndex(1)
                        }
                    }
                    .frame(height: 90)
                    .background(Color.main)
                    .zIndex(5)
                }
                Spacer()
                /// Bottom right buttons
                if JMapManager.shared.pubOrigin.count > 0 && JMapManager.shared.pubDestination.count > 0 {
                    VStack{
                        Spacer()
                        HStack{
                            Spacer()
                            Button(action: {
                                jmapManager.pubPresentStepsPanel = true
                                jmapManager.pubPresentTurnbyTurnNote = true
                            }, label: {
                                HStack{
                                    Image(systemName: "note.text")
                                        .resizable()
                                        .foregroundColor(Color.white)
                                        .frame(width:30, height:30)
                                        .padding(5)
                                }
                                .frame(width:45, height:45)
                                .background(Color.main)
                                .cornerRadius(10)
                            })
                            Spacer().frame(width:20)
                        }
                        Spacer().frame(height: ScreenSize.safeBottom() + 75)
                    }.zIndex(2)
                }
            }.zIndex(4)
            
            if jmapManager.pubAudioAlertDialog {
                HStack{
                    Spacer()
                    VStack{
                        Spacer()
                        VStack(alignment:.center){
                            Spacer()
                            Image(systemName: "\(jmapManager.pubAudioAlert ? "bell.fill" : "bell.slash.fill")").resizable().foregroundColor(Color.white).frame(width:65, height:65).padding(5)
                            Text("Audio Notification is turned \(jmapManager.pubAudioAlert ? "ON" : "OFF")").bold().foregroundStyle(Color.white).padding(30)
                            Spacer()
                        }
                        .background(Color.main)
                        .frame(height:200)
                        .cornerRadius(20)
                        Spacer()
                    }
                    Spacer()
                }
                .background(Color.black.opacity(0.6))
                .zIndex(5)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}
