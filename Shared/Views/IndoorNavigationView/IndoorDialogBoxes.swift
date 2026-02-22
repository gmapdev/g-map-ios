//
//  IndoorDialogBoxes.swift
//

import Foundation
import SwiftUI

// This has All Indoor Dialog Boxes

struct IndoorNavigationDialog: View {
    
    @ObservedObject var indoor = IndoorNavigationManager.shared
    @ObservedObject var jmapManager = JMapManager.shared
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        return ZStack{
            VStack{
                Spacer()
                HStack(){
                    Spacer()
                }
                Spacer()
            }
            .background(Color.black.opacity(0.7))
            .zIndex(1)
            
            VStack{
                Spacer().frame(height: 100 + ScreenSize.safeTop())
                Spacer()
                HStack{
                    Spacer().frame(width: 30)
                    ZStack{
                        VStack{
                            Spacer()
                            HStack(){
                                Spacer()
                            }
                            Spacer()
                        }
                        .background(.white)
                        .cornerRadius(10)
                        
                        VStack(alignment: .center, spacing: 0){
                            Spacer().frame(height:10)
                            HStack{
                                Spacer()
                                Image(systemName: "location.circle").resizable().frame(width:20, height:20)
                                TextLabel("You have arrived at:".localized(), .bold).foregroundStyle(Color.black)
                                Spacer()
                            }
                            .padding(10)
                            HStack{
                                Spacer().frame(width:10)
                                TextLabel("\(MapFromToViewModel.shared.pubToString.capitalizingFirstLetter())".localized(), .bold).foregroundStyle(Color.gray).fixedSize(horizontal: false, vertical: true)
                                Spacer().frame(width:10)
                            }.padding(10)
                            HStack{
                                Spacer().frame(width:10)
                                TextLabel("Do you want to open indoor navigation?".localized(), .bold)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer().frame(width:10)
                            }.padding(10)
                            HStack{
                                Spacer().frame(width:10)
                                Image("ic_building")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                TextLabel("Indoor navigation is available when the button is visible in the top left corner.".localized(), .bold).foregroundStyle(Color.gray)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer().frame(width:10)
                            }.padding(10)
                            
                            Spacer().frame(height:20)
                            HStack{
                                Spacer().frame(width:10)
                                Button(action: {
                                    JMapManager.venueId = IndoorNavigationManager.shared.pubJMapVenueId
                                    /// Initializes a new instance.
                                    JMapManager.shared.initialization()
                                    if let loginInfo = AppSession.shared.loginInfo {
                                        ProfileManager.shared.isHapticFeedbackOpen = loginInfo.notificationChannel.contains("haptic")
                                    }
                                    IndoorNavigationManager.shared.pubPresentIndoorNavDialog = false
                                }, label: {
                                    HStack{
                                        Spacer()
                                        TextLabel("Cancel".localized()).font(.body).foregroundColor(Color.white).padding(15)
                                        Spacer()
                                    }
                                    .background(Color.secondary)
                                    .cornerRadius(5)
                                })
                                Spacer()
                                Button(action: {
                                    JMapManager.venueId = IndoorNavigationManager.shared.pubJMapVenueId
                                    /// Initializes a new instance.
                                    JMapManager.shared.initialization()
                                    if let loginInfo = AppSession.shared.loginInfo {
                                        ProfileManager.shared.isHapticFeedbackOpen = loginInfo.notificationChannel.contains("haptic")
                                    }
                                    JMapManager.shared.startUniversalTimer()
                                    IndoorNavigationManager.shared.pubPresentIndoorNavDialog = false
                                    IndoorNavigationManager.shared.pubPresentIndoorNavigationView = true
                                    if LiveRouteManager.shared.pubIsRouteActivated {
                                        // If we are in the activated route mode, then, we disable it
                                        LiveRouteManager.shared.resetLiveTracking()
                                    }
                                }, label: {
                                    HStack{
                                        Spacer()
                                        TextLabel("Open".localized()).font(.body).foregroundColor(Color.white).padding(15)
                                        Spacer()
                                    }
                                    .background(Color.main)
                                    .cornerRadius(5)
                                })
                                Spacer().frame(width:10)
                            }
                        }
                        Spacer().frame(height:20)
                    }
                    .frame(height:330)
                    Spacer().frame(width: 30)
                }
                Spacer()
                Spacer().frame(height: 100 + ScreenSize.safeBottom())
            }
            .zIndex(2)
        }
        
    }
}

struct IndoorEntranceDialog: View {
    
    @ObservedObject var indoor = IndoorNavigationManager.shared
    @ObservedObject var jmapManager = JMapManager.shared
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        return ZStack{
            VStack{
                Spacer()
                HStack(){
                    Spacer()
                }
                Spacer()
            }
            .background(Color.black.opacity(0.7))
            .zIndex(1)
            
            VStack{
                Spacer().frame(height: (AccessibilityManager.shared.pubIsLargeFontSize ? 0 : 65) + ScreenSize.safeTop())
                Spacer()
                HStack{
                    Spacer().frame(width: 30)
                    ZStack{
                        VStack{
                            Spacer()
                            HStack(){
                                Spacer()
                            }
                            Spacer()
                        }
                        .background(.white)
                        .cornerRadius(10)
                        
                        VStack(alignment: .center, spacing: 0){
                            Spacer().frame(height:10)
                            // Title
                            HStack{
                                Spacer().frame(width:10)
                                TextLabel(indoor.pubIndoorEntranceDialogTitle ?? "".localized(), .bold)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer().frame(width:10)
                            }.padding(10)
                            
                            // Message
                            ScrollView{
                                HStack{
                                    Spacer().frame(width:10)
                                    TextLabel(indoor.pubIndoorEntranceDialogMessage ?? "".localized(), .bold).foregroundStyle(Color.gray)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer().frame(width:10)
                                }.padding(5)
                            }.frame(minHeight: 200)
                            Spacer().frame(height:10)
                            
                            HStack{
                                Spacer()
                                Button(action: {
                                    IndoorNavigationManager.shared.pubPresentIndoorEntranceDialog = false
                                    TravelIQAudio.shared.stop()
                                }, label: {
                                    HStack{
                                        TextLabel("OK".localized()).font(.body).foregroundColor(Color.white).padding(15)
                                    }
                                    .frame(width: 100, height: 50)
                                    .background(Color.main)
                                    .cornerRadius(10)
                                })
                                Spacer()
                            }.padding(.bottom, 10)
                        }
                        Spacer().frame(height:20)
                    }
                    .frame(height:AccessibilityManager.shared.pubIsLargeFontSize ? 600 : 430)
                    Spacer().frame(width: 30)
                }
                Spacer()
                Spacer().frame(height:(AccessibilityManager.shared.pubIsLargeFontSize ? 0 : 65) + ScreenSize.safeBottom())
            }
            .zIndex(2)
            .onAppear{
                TravelIQAudio.shared.playAudio(fromText: indoor.pubIndoorEntranceDialogTitle ?? "", parameters: nil, highPriority: false, ignoreError: true) { _, _, _ in }
                TravelIQAudio.shared.playAudio(fromText: indoor.pubIndoorEntranceDialogMessage ?? "", parameters: nil, highPriority: false, ignoreError: true) { _, _, _ in }
            }
        }
    }
}

struct IndoorDeviatedDialog: View {
    
    @ObservedObject var indoor = IndoorNavigationManager.shared
    @ObservedObject var jmapManager = JMapManager.shared
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        return ZStack{
            VStack{
                Spacer()
                HStack(){
                    Spacer()
                }
                Spacer()
            }
            .background(Color.black.opacity(0.7))
            .zIndex(1)
            
            VStack{
                Spacer().frame(height: 100 + ScreenSize.safeTop())
                Spacer()
                HStack{
                    Spacer().frame(width: 50)
                    ZStack{
                        VStack{
                            Spacer()
                            HStack(){
                                Spacer()
                            }
                            Spacer()
                        }
                        .background(Color.main)
                        .cornerRadius(10)
                        
                        VStack(alignment: .leading){
                            Spacer().frame(height:10)
                            HStack{
                                Spacer()
                                TextLabel("Attention".localized(), .bold, .title).foregroundStyle(Color.white)
                                Spacer()
                            }
                            .padding(10)
                            HStack{
                                Spacer().frame(width:10)
                                TextLabel("Looks like you deviated from your route. Do you want to re-route?".localized(), .regular, .title2).foregroundStyle(Color.white)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer().frame(width:10)
                            }.onAppear{
                                if jmapManager.pubAudioAlert{
                                    TravelIQAudio.shared.playAudio(fromText: "Looks like you deviated from your route. Do you want to re-route?", parameters: nil, highPriority: false, ignoreError: true){ state, errorMessage, parameters in}
                                }
                            }
                            
                            Spacer().frame(height:20)
                            HStack{
                                Spacer().frame(width:10)
                                Button(action: {
                                    IndoorNavigationManager.shared.pubPresentIndoorDeviationDialog = false
                                    JMapManager.shared.deviationCancelCounter += 1
                                }, label: {
                                    HStack{
                                        Spacer()
                                        TextLabel("Cancel".localized(), .regular, .body).foregroundColor(Color.white).padding(15)
                                        Spacer()
                                    }
                                    .background(Color.gray)
                                    .cornerRadius(5)
                                })
                                .disabled(jmapManager.pubIsRerouting)
                                Spacer()
                                Button(action: {
                                    JMapManager.shared.reRouteWithNearestWayPoint { success in
                                        if success {
                                            IndoorNavigationManager.shared.pubPresentIndoorDeviationDialog = false
                                            JMapManager.shared.checkDeviationInterval = FeatureConfig.shared.indoor_nav_deviation_popup_wait_time_seconds
                                            JMapManager.shared.nextDeviationTimeStemp = Date().timeIntervalSince1970
                                            JMapManager.shared.deviationCancelCounter = 0
                                        }
                                        // if for some reason the reroute not possible what we should do on the UI side, eventhough we are shouwing the Toast Message
                                        else{
                                            IndoorNavigationManager.shared.pubPresentIndoorDeviationDialog = false
                                            AlertManager.shared.presentAlert(message: "CXApp was unable to reroute. Please try searching again.")
                                            JMapManager.shared.deviationCancelCounter = 0
                                        }
                                    }
                                }, label: {
                                    HStack{
                                        Spacer()
                                        if jmapManager.pubIsRerouting {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .scaleEffect(0.9)
                                                .padding(.trailing, 6)
                                        }
                                        TextLabel(jmapManager.pubIsRerouting ? "Re-routing...".localized() : "Yes".localized(), .regular, .body)
                                            .foregroundColor(Color.white)
                                            .padding(15)
                                        Spacer()
                                    }
                                    .background(Color.green)
                                    .cornerRadius(5)
                                })
                                .disabled(jmapManager.pubIsRerouting)
                                Spacer().frame(width:10)
                            }
                        }
                        .background(Color.main)
                        Spacer().frame(height:20)
                    }
                    .cornerRadius(10)
                    .frame(height:ScreenSize.height() * 0.30)
                    Spacer().frame(width: 50)
                }
                
                Spacer()
                Spacer().frame(height: 100 + ScreenSize.safeBottom())
            }
            .zIndex(2)
        }
    }
}

struct IndoorExitDirectionDialog: View {
    
    @ObservedObject var indoor = IndoorNavigationManager.shared
    @ObservedObject var jmapManager = JMapManager.shared
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        return ZStack{
            VStack{
                Spacer()
                HStack(){
                    Spacer()
                }
                Spacer()
            }
            .background(Color.black.opacity(0.7))
            .zIndex(1)
            
            VStack{
                Spacer().frame(height: 100 + ScreenSize.safeTop())
                Spacer()
                HStack{
                    Spacer().frame(width: 50)
                    ZStack{
                        VStack{
                            Spacer()
                            HStack(){
                                Spacer()
                            }
                            Spacer()
                        }
                        .background(Color.main)
                        
                        
                        VStack(alignment: .leading){
                            ZStack{
                                VStack{
                                    HStack{
                                        Spacer()
                                        Button(action: {
                                            indoor.pubPresentIndoorExitDirectionDialog = false
                                        }, label: {
                                            HStack{
                                                Image("ic_cancel")
                                                    .renderingMode(.template)
                                                    .resizable().aspectRatio(contentMode: .fit)
                                                    .foregroundColor(Color.main)
                                                    .frame(width: 20, height: 20, alignment: .center)
                                            }
                                            .frame(width: 35, height: 35)
                                            .background(Color.white)
                                            .cornerRadius(17.5)
                                        })
                                    }.padding(.trailing, 10)
                                    Spacer()
                                }.padding(.top, 10).zIndex(1)
                                VStack{
                                    // Content
                                    Spacer().frame(height:10)
                                    HStack{
                                        Spacer()
                                        TextLabel("Attention".localized(),.bold, .title).foregroundStyle(Color.white)
                                        Spacer()
                                    }
                                    .padding(10)
                                    HStack{
                                        Spacer().frame(width:8)
                                        Text(IndoorNavigationManager.shared.pubIndoorExitDialogBoxMessage ?? "")
                                            .font(.title2).foregroundStyle(Color.white)
                                            .fixedSize(horizontal: false, vertical: true)
                                        Spacer().frame(width:8)
                                    }
                                    Spacer().frame(height:20)
                                    VStack(alignment:.leading){
                                        HStack{
                                            Spacer()
                                            Button(action: {
                                                // Navigate to another room in the building
                                                indoor.pubPresentIndoorExitDirectionDialog = false
                                                indoor.pubPresentSearchPanel = true
                                            }, label: {
                                                HStack{
                                                    Text("Navigate to another room in the building".localized()).bold().foregroundColor(Color.black).padding(15)
                                                    Spacer()
                                                }
                                                .background(Color.gray)
                                            }).buttonStyle(BackgoundChangeOnTapStyle())
                                            Spacer()
                                        }
                                        
                                        HStack{
                                            Spacer()
                                            Button(action: {
                                                // "Continue with indoor navigation"
                                                indoor.pubPresentIndoorExitDirectionDialog = false
                                            }, label: {
                                                HStack{
                                                    Text("Continue with indoor navigation".localized()).bold().foregroundColor(Color.black).padding(15)
                                                    Spacer()
                                                }
                                                .background(Color.gray)
                                            }).buttonStyle(BackgoundChangeOnTapStyle())
                                            Spacer()
                                        }
                                        
                                        HStack{
                                            Spacer()
                                            Button(action: {
                                                // "Start a saved trip"
                                                indoor.openSavedTrips()
                                            }, label: {
                                                HStack{
                                                    Text("Start a saved trip".localized()).bold().foregroundColor(Color.black).padding(15)
                                                    Spacer()
                                                }
                                                .background(Color.gray)
                                            }).buttonStyle(BackgoundChangeOnTapStyle())
                                            Spacer()
                                        }
                                    }
                                }.zIndex(2)
                            }
                        }
                        .background(Color.main)
                        Spacer().frame(height:20)
                    }
                    .cornerRadius(15)
                    .frame(height:ScreenSize.height() * 0.50)
                    Spacer().frame(width: 50)
                }
                Spacer()
                Spacer().frame(height: 100 + ScreenSize.safeBottom())
            }.cornerRadius(10)
            .zIndex(2)
        }
    }
}


class IndoorGenericDialogManager: ObservableObject {
    
    @Published var pubPresentIndoorGenericDialog = false
    var title: String = ""
    var message: String = ""
    var primaryButtonText: String?
    var secondaryButtonText: String?
    var onConfirm: ((String)-> Void)?
    
    /// Shared.
    /// - Parameters:
    ///   - IndoorGenericDialogManager: Parameter description
    public static var shared: IndoorGenericDialogManager = {
        let mgr = IndoorGenericDialogManager()
        return mgr
    }()
    
    /// Present.
    /// - Parameters:
    ///   - title: Parameter description
    ///   - message: Parameter description
    ///   - primaryButtonText: Parameter description
    ///   - secondaryButtonText: Parameter description
    ///   - onConfirm: Parameter description
    /// - Returns: Void)?)
    public func present(title: String, message: String, primaryButtonText: String?, secondaryButtonText: String?, onConfirm: ((String)->Void)?){
        self.title = title
        self.message = message
        self.primaryButtonText = primaryButtonText
        self.secondaryButtonText = secondaryButtonText
        self.onConfirm = onConfirm
        pubPresentIndoorGenericDialog = true
    }
}

struct IndoorGenericDialog: View {
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        var buttonText = IndoorGenericDialogManager.shared.primaryButtonText ?? ""
        if buttonText.count <= 0 {
            buttonText = IndoorGenericDialogManager.shared.secondaryButtonText ?? ""
        }
        return ZStack{
            VStack{
                Spacer()
                HStack(){
                    Spacer()
                }
                Spacer()
            }
            .background(Color.black.opacity(0.7))
            .zIndex(1)
            
            VStack{
                Spacer().frame(height: 100 + ScreenSize.safeTop())
                Spacer()
                HStack{
                    Spacer().frame(width: 50)
                    ZStack{
                        VStack{
                            Spacer()
                            HStack(){
                                Spacer()
                            }
                            Spacer()
                        }
                        .background(Color.main)
                        .cornerRadius(10)
                        
                        VStack(alignment: .leading){
                            Spacer().frame(height:10)
                            HStack{
                                Spacer()
                                TextLabel(IndoorGenericDialogManager.shared.title, .bold, .title).foregroundStyle(Color.white)
                                Spacer()
                            }
                            .padding(10)
                            HStack{
                                Spacer().frame(width:10)
                                TextLabel(IndoorGenericDialogManager.shared.message, .regular, .title2).foregroundStyle(Color.white)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer().frame(width:10)
                            }
                            
                            Spacer().frame(height:20)
                            HStack{
                                Spacer().frame(width:10)
                                
                                if let pButtonText = IndoorGenericDialogManager.shared.primaryButtonText,
                                   let sButtonText = IndoorGenericDialogManager.shared.secondaryButtonText{
                                    Button(action: {
                                        IndoorGenericDialogManager.shared.onConfirm?(sButtonText)
                                        IndoorGenericDialogManager.shared.pubPresentIndoorGenericDialog = false
                                    }, label: {
                                        HStack{
                                            Spacer()
                                            TextLabel(sButtonText, .regular, .body).foregroundColor(Color.white).padding(15)
                                            Spacer()
                                        }
                                        .background(Color.gray)
                                        .cornerRadius(5)
                                    })
                                    Spacer()
                                    Button(action: {
                                        IndoorGenericDialogManager.shared.onConfirm?(pButtonText)
                                        IndoorGenericDialogManager.shared.pubPresentIndoorGenericDialog = false
                                    }, label: {
                                        HStack{
                                            Spacer()
                                            TextLabel(pButtonText, .regular, .body).foregroundColor(Color.white).padding(15)
                                            Spacer()
                                        }
                                        .background(Color.green)
                                        .cornerRadius(5)
                                    })
                                }
                                else{
                                    Spacer()
                                    Button(action: {
                                        IndoorGenericDialogManager.shared.onConfirm?(buttonText)
                                        IndoorGenericDialogManager.shared.pubPresentIndoorGenericDialog = false
                                    }, label: {
                                        HStack{
                                            Spacer()
                                            TextLabel(buttonText, .regular, .body).foregroundColor(Color.white).padding(15)
                                            Spacer()
                                        }
                                        .frame(width:80)
                                        .background(Color.green)
                                        .cornerRadius(5)
                                    })
                                    Spacer()
                                }
                                
                                Spacer().frame(width:10)
                            }
                        }
                        .background(Color.main)
                        Spacer().frame(height:20)
                    }
                    .cornerRadius(10)
                    .frame(height:ScreenSize.height() * 0.30)
                    Spacer().frame(width: 50)
                }
                
                Spacer()
                Spacer().frame(height: 100 + ScreenSize.safeBottom())
            }
            .zIndex(2)
        }
    }
}


struct BackgoundChangeOnTapStyle: ButtonStyle {

  /// Make body.
  /// - Parameters:
  ///   - configuration: Parameter description
  /// - Returns: some View
  func makeBody(configuration: Self.Configuration) -> some View {
    configuration.label
      .background(configuration.isPressed ? Color.green : Color.gray)
      .cornerRadius(10)
  }

}

