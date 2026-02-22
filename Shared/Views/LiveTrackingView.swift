//
//  LiveTrackingView.swift
//

import SwiftUI

struct LiveTrackingView: View {
    
    @ObservedObject var liveRouteManager = LiveRouteManager.shared
	@ObservedObject var previewStepManager = PreviewTripManager.shared
    @ObservedObject var mapManager = MapManager.shared
	
    var (timeText, _) = TripPlanningManager.shared.timeText(for: String(TripPlanningManager.shared.pubSelectedItinerary?.duration ?? 0))
    let endTimeText = TripPlanningManager.shared.milliSecondsTime(time: String(TripPlanningManager.shared.pubSelectedItinerary?.endTime ?? 0))
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
		let currentStepIndex = PreviewTripManager.shared.currentStepIndex
		var currentStep: PreviewTripStep?
		if PreviewTripManager.shared.currentTripSteps.count > PreviewTripManager.shared.currentStepIndex {
			currentStep = PreviewTripManager.shared.currentTripSteps[currentStepIndex]
		}
        return ZStack{
            
            VStack{
                if liveRouteManager.pubIsShowRouteDetails || liveRouteManager.pubIsPreviewMode {
                    ScrollViewReader { scrollviewManager in
                        VStack{
                            Spacer().frame(height: liveRouteManager.pubIsPreviewMode ? ScreenSize.height() * 0.4 : ScreenSize.height() * 0.21)
                            VStack {
                                Spacer().frame(height: 15)
                                if !liveRouteManager.pubIsPreviewMode {
                                    HStack{
                                        TextLabel("Details of Trip".localized(), .regular, .body)
                                            .foregroundColor(.black)
                                            .padding(.horizontal, 10)
                                        Spacer()
                                        Button {
                                            liveRouteManager.pubIsShowRouteDetails = false
                                        } label: {
                                            Image("ic_cancel")
                                                .resizable()
                                                .frame(width: 17, height: 17)
                                                .foregroundColor(.black)
                                                .padding(.horizontal, 20)
                                        }
                                    }
                                }
                                else{
                                    HStack{
                                        Spacer().frame(width:20)
                                        if !PreviewTripManager.shared.isFirstLegFirstStep(){
                                            Button(action: {
                                                let id = PreviewTripManager.shared.previousStep()
                                                scrollviewManager.scrollTo(id)
                                            }, label: {
                                                VStack{
                                                    Image(systemName: "chevron.left.square.fill").renderingMode(.template).resizable().frame(width:35, height:35).foregroundColor(Color.main)
                                                }.padding(0)
                                                    .addAccessibility(text: "\(currentStep?.description ?? ""),click to move to previous instruction")
                                            })
                                            Spacer().frame(width:15)
                                        }
                                        VStack{
                                            Spacer()
                                            HStack{
                                                Image(uiImage: UIImage(named: currentStep?.image ?? "map_location_move_icon")!).resizable().renderingMode(.template).foregroundColor(Color.black).frame(width:40, height:40)
                                                Text(currentStep?.description ?? "").font(.system(size: 18)).bold().foregroundStyle(Color.black)
                                            }.padding(0)
                                            HStack{
                                                Spacer()
                                                Text(Helper.shared.formattedDistanceDescription(previewStepManager.currentTripSteps[currentStepIndex].distance, withLabel : true)).font(.system(size: 14)).foregroundStyle(Color.black)
                                                Spacer()
                                            }.padding(0)
                                            Spacer()
                                            HStack{
                                                Spacer()
                                                Text("\(currentStepIndex + 1) / \( previewStepManager.currentTripSteps.count)").font(.system(size: 12)).foregroundStyle(Color.gray)
                                                Spacer()
                                            }.padding(0)
                                            
                                        }
                                        .padding(0)
                                        Spacer().frame(width:15)
                                        if !PreviewTripManager.shared.isLastLegLastStep(){
                                            Button(action: {
                                                let id = PreviewTripManager.shared.nextStep()
                                                scrollviewManager.scrollTo(id)
                                            }, label: {
                                                VStack{
                                                    Image(systemName: "chevron.right.square.fill").renderingMode(.template).resizable().frame(width:35, height:35).foregroundColor(Color.main)
                                                }
                                                .addAccessibility(text: "\(currentStep?.description ?? ""),click to move to next instruction")
                                            })
                                            Spacer().frame(width:20)
                                        }
                                    }
                                    .padding(0)
                                    .frame(maxHeight: 120)
                                }
                                
                                
                                ScrollView{
                                    Spacer().frame(height: 5)
                                    
                                    if !liveRouteManager.pubIsPreviewMode {
                                        VStack(alignment: .leading){
                                            HStack{
                                                TextLabel("Arrive at \(endTimeText)".localized(), .regular, .title3)
                                                    .foregroundColor(.black)
                                                    .padding(.leading, 25)
                                                    .padding(.trailing, 10)
                                                Spacer()
                                            }
                                            HStack{
                                                TextLabel("Total Time Spent: \(timeText)".localized(), .regular, .headline)
                                                    .foregroundColor(.black)
                                                    .padding(.leading, 25)
                                                    .padding(.trailing, 10)
                                                Spacer()
                                            }
                                            HStack{
                                                TextLabel(liveRouteManager.getTotalDistanceOfTrip().localized(), .regular, .callout)
                                                    .foregroundColor(.black)
                                                    .padding(.leading, 25)
                                                    .padding(.trailing, 10)
                                                Spacer()
                                            }
                                        }
                                    }
                                    
                                    VStack{
                                        if let itinerary = TripPlanningManager.shared.pubSelectedItinerary {
                                            ItineraryLegsView(itinerary: itinerary, stopViewerAction: { tappedItinerary, tappedOTPLeg in
                                                StopViewerViewModel.shared.pubIsShowingStopViewer = true    // Showing the Stop Viewer from Live Tracking.
                                            })
                                            .padding(.horizontal, 10)
                                        }
                                    }
                                }
                            }
                            .frame(width:liveRouteManager.pubIsPreviewMode ? ScreenSize.width() : ScreenSize.width() - 50)
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 10)
                            
                            Spacer().frame(height: ScreenSize.safeBottom())
                        }
                    }
                }else{
                    // Bottom Instructions View
                    VStack{
                        Spacer()
                        speakerButtonView.padding(.bottom,10)
                        locateMeView.padding(.bottom,10)
                        VStack{
                            HStack{
                                VStack(alignment: .leading, spacing: 5){
                                    TextLabel(liveRouteManager.pubServerInstructions.localized(), .semibold, .title3)
                                        .foregroundColor(.black)
                                        .padding(.leading, 10)
                                    TextLabel(liveRouteManager.pubServerMessage.localized(), .semibold, .callout)
                                        .foregroundColor(.black)
                                        .padding(.leading, 10)
                                }.padding(.leading, 10)
                                Spacer()
                                VStack{
                                    Button {
                                        liveRouteManager.pubIsShowRouteDetails = true
                                    } label: {
                                        Image(systemName: "doc.text.magnifyingglass")
                                            .resizable()
                                            .frame(width: 35, height: 40)
                                            .foregroundColor(.black)
                                            .padding(.trailing, 20)
                                    }
                                }
                            }
                        }
                        .frame(width:ScreenSize.width() - 50, height: 100)
                        .background(Color.main)
                        .cornerRadius(10)
                        .shadow(radius: 10)
                        
                    }
                    Spacer().frame(height: 50)
                }
            }.zIndex(1)
            // Custom Audio Alert Dialogbox
            if liveRouteManager.pubLiveTrackingAudioAlertDialog {
                HStack{
                    Spacer()
                    VStack{
                        Spacer()
                        VStack(alignment:.center){
                            Spacer()
                            Image(systemName: "\(liveRouteManager.pubLiveTrackingAudioAlert ? "bell.fill" : "bell.slash.fill")").resizable().foregroundColor(Color.white).frame(width:65, height:65).padding(5)
                            Text("Audio Notification is turned \(liveRouteManager.pubLiveTrackingAudioAlert ? "ON" : "OFF")").bold().foregroundStyle(Color.white).padding(30)
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
            if liveRouteManager.tripHasEndedStatus{
                ZStack{
                    VStack{
                        Spacer()
                        HStack(){
                            Spacer()
                        }
                        Spacer()
                    }.ignoresSafeArea(.container)
                    .background(Color.black.opacity(0.7))
                    .zIndex(100)
                    
                    VStack{
                        HStack{
                            Spacer()
                            Image(systemName: "location.circle")
                                .resizable()
                                .frame(width: 20, height: 20)
                            TextLabel("Destination Arrived", .bold, .title3)
                            Spacer()
                        }
                        HStack{
                            Spacer()
                            TextLabel(liveRouteManager.getToNameOfTrip(), .regular, .title3)
                                .foregroundColor(.gray)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer()
                        }.padding()
                        HStack{
                            Button {
                                liveRouteManager.resetLiveTracking()
                            } label: {
                                HStack{
                                    TextLabel("OK", .regular, .title3)
                                        .foregroundColor(.black)
                                }
                                .padding(.horizontal, 40)
                                .padding(.vertical, 15)
                            }
                            .background(Color.main)
                            .cornerRadius(5)

                        }
                        
                    }
                    .frame(width: ScreenSize.width() * 0.75, height: ScreenSize.height() * 0.28)
                    .background(Color.white)
                    .cornerRadius(10)
                    .zIndex(200)
                    
                }.zIndex(2)
            }
            
            if GenericDialogBoxManager.shared.pubPresentGenericDialogBox {
                GenericDialogBox().edgesIgnoringSafeArea(.all).zIndex(9999)
            }
            
            if liveRouteManager.pubLiveTrackingLoading {
                LoadingViewFullPage(showBackground: true)
            }
        }
    }
    /// Speaker button view.
    /// - Parameters:
    ///   - some: Parameter description
    private var speakerButtonView: some View {
        HStack{
            Spacer()
            Button(action: {
                liveRouteManager.pubLiveTrackingAudioAlertDialog = true
                liveRouteManager.pubLiveTrackingAudioAlert.toggle()
                DispatchQueue.main.asyncAfter(deadline: .now() + 3){
                    liveRouteManager.pubLiveTrackingAudioAlertDialog = false
                }
            }, label: {
                HStack{
                    Image(systemName: liveRouteManager.pubLiveTrackingAudioAlert ? "bell" : "bell.slash")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(liveRouteManager.pubLiveTrackingAudioAlert ? .white : .gray)
                        .frame(width:30, height:30)
                        .padding(5)
                }
                .frame(width:50, height:50)
                .background(liveRouteManager.pubLiveTrackingAudioAlert ? Color.main : Color.white)
                .clipShape(Circle())
                .shadow(radius: 5)
            })
            Spacer().frame(width:25)
        }
    }
    /// Locate me view.
    /// - Parameters:
    ///   - some: Parameter description
    private var locateMeView: some View {
        HStack{
            Spacer()
            HStack{
                Button(action: {
                    withAnimation {
                        mapManager.followMe(enable: !mapManager.isLocateMe)
                    }
                }) {
                    Image("map_locateme_icon")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(mapManager.isLocateMe ?  .white : .gray)
                        .frame(width: 30, height: 30, alignment: .center)
                }
                
            }.frame(width: 50, height: 50)
                .background(mapManager.isLocateMe ?  Color.main : Color.white)
                .clipShape(Circle())
                .shadow(radius: 5)
    
            Spacer().frame(width:25)
        }
    }
}

#Preview {
    LiveTrackingView()
}
