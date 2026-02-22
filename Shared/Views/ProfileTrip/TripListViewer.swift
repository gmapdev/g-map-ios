//
//  TripListViewer.swift
//

import SwiftUI

/// If we have trips, then we show the list of trips, otherwise, show empty
struct TripListViewer: View {
	
	@ObservedObject var profileManager = ProfileManager.shared
	
	@State var presentLoadingView: Bool = false
	
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
		let tripItems = profileManager.tripNotificationList
        return
            VStack{
                if let loginInfo = AppSession.shared.loginInfo , loginInfo.emailIsVerified {
                    if profileManager.pubHasConsentedToTerms{
                        if profileManager.tripNotificationErrorMessage.count > 0 {
                            Spacer()
                            TextLabel(profileManager.tripNotificationErrorMessage).padding(20).foregroundColor(Color.white)
                            Spacer()
                        } else{
                            if profileManager.pubTripNotificationLoading == true{
                                LoadingViewFullPage(showBackground: false)
                            }
                            if tripItems.count > 0 {
                                ScrollView{
                                    ForEach(0..<tripItems.count, id:\.self){ idx in
                                        if AccessibilityManager.shared.pubIsLargeFontSize {
                                            SavedTripItemViewAODA(item: tripItems[idx], processing: self.$presentLoadingView)
                                        } else {
                                            SavedTripItemView(item: tripItems[idx], processing: self.$presentLoadingView)
                                        }
                                    }
                                }
                                .padding(.horizontal, 15)
                            }else if tripItems.count == 0 && profileManager.pubTripNotificationLoading == false{
                                emptyTripView()
                            }
                        }
                    }else{
                        Spacer()
                        TextLabel("Please agree to the terms of service to save favorite trips.".localized()).padding(20).foregroundColor(Color.white)
                        Spacer()
                    }
                }else {
                    Spacer()
                    TextLabel("Please verify your email before saving your favorite trips.".localized()).padding(20).foregroundColor(Color.white)
                    Spacer()
                }
            }
    }
	
 /// Empty trip view
 /// - Returns: some View
 /// Empty trip view.
	func emptyTripView() -> some View {
		VStack{
			HStack{
                TextLabel("You have no saved trips".localized()).font(.largeTitle).foregroundColor(Color.white)
				Spacer()
			}
			.padding(.bottom, 20)
			
			HStack{
                TextLabel("Perform a trip search from the map first.".localized()).font(.subheadline).lineLimit(nil).foregroundColor(Color.white)
                Spacer()
            }
            Spacer()
        }
        .padding(40)
    }
}

struct SavedTripItemView: View {

    @Inject var auth0Provider: LoginAuthProvider
    @Inject var notificationProvider: NotificationProvider

    @ObservedObject var profileManager = ProfileManager.shared
    @State var item: TripNotificationResponse
    @Binding var processing: Bool
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        var isTripEditable = profileManager.isTripEditable(item)
        return VStack(alignment: .center, spacing: 10, content: {
            HStack{
                TextLabel("\(item.tripName)", .bold, .title)
                Spacer()
                TripPlanningManager.shared.SavedTripListTransportsView(itinerary: item.itinerary)
                
            }.padding(.horizontal,10).padding(.top, 10)
                .addAccessibility(text: "%1, %2".localized(item.tripName,TripPlanningManager.shared.prepareTransportViewString(itinerary: item.itinerary)))
            
            HStack{
                VStack{
                    HStack{
                        Image("ic_origin")
                            .resizable()
                            .frame(width: 25, height: 25, alignment: .center)
                        TextLabel("\(item.from.name)", .bold, .body)
                        Spacer()
                    }
                    HStack{
                        Image("ic_location")
                            .resizable()
                            .frame(width: 25, height: 25, alignment: .center)
                        TextLabel("\(item.to.name)", .bold, .body)
                        Spacer()
                    }
                }
                Spacer()
                VStack{
                    TripPlanningManager.shared.transportsTimeView(itinerary: item.itinerary)
                    Spacer()
                }
            }.padding(.horizontal,10)
                .addAccessibility(text: "From %1 To %2".localized(item.from.name, item.to.name))
            
            HStack{
                Image("ic_alert")
                    .resizable()
                    .frame(width: 25, height: 25, alignment: .center)
                
                if item.isActive{
                    VStack{
                        HStack{
                            TextLabel(Helper.shared.formatReadableMins(mins: item.leadTimeInMinutes),.bold,.body)
                            Spacer()
                        }
                        HStack{
                            TextLabel("Before scheduled departure".localized()).foregroundColor(Color.gray_subtitle_color)
                                .font(.body)
                            Spacer()
                        }
                    }
                }
                else{
                    TextLabel("Disabled".localized())
                        .font(.body)
                }
                Spacer()
            }.padding(.horizontal,10)
                .addAccessibility(text: "%1, Before scheduled departure".localized(Helper.shared.formatReadableMins(mins: item.leadTimeInMinutes)))
            HStack{
                Image("ic_schedule")
                    .resizable()
                    .frame(width: 25, height: 25, alignment: .center)
                TextLabel("\(weekdayDescription())".localized(), .bold, .body)
                Spacer()
            }.padding(.horizontal,10)
                .addAccessibility(text: "%1".localized(weekdayDescription()))
            
            Divider().background(Color.gray.opacity(0.77))
            
            HStack(alignment: .center, spacing:0, content: {
                Group{
                    Spacer()
                    if !(item.isActive) {
                        Button(action: {
                            item.isActive = true
                            updateTripModelItem()
                            ProfileTripModel.shared.storeNotificationToServer(creation: profileManager.tripManagerState.isCreation){ success, errorMessage in }
                        }, label: {
                            VStack{
                                Image(systemName: "bell")
                                    .resizable()
                                    .foregroundColor(isTripEditable ? .black : .gray_subtitle_color)
                                    .frame(width: 30, height: 30, alignment: .center)
                                TextLabel("Notification", .bold, .caption3).foregroundColor(isTripEditable ? .black : .gray_subtitle_color)
                            }
                        })
                        .addAccessibility(text: AvailableAccessibilityItem.resumeButton.rawValue.localized())
                    }
                    else{
                        Button(action: {
                            item.isActive = false
                            updateTripModelItem()
                            ProfileTripModel.shared.storeNotificationToServer(creation: profileManager.tripManagerState.isCreation){ success, errorMessage in }
                        }, label: {
                            VStack{
                                Image(systemName: "bell.slash")
                                    .resizable()
                                    .foregroundColor(isTripEditable ? .black : .gray_subtitle_color)
                                    .frame(width: 30, height: 30, alignment: .center)
                                TextLabel("Notification", .black, .caption3).foregroundColor(isTripEditable ? .black : .gray_subtitle_color)
                            }
                        })
                        .addAccessibility(text: AvailableAccessibilityItem.pauseButton.rawValue.localized())
                    }
                    
                    Spacer()
                    Divider().background(Color.gray.opacity(0.77))
                    Spacer()
                }
                .disabled(!isTripEditable)
                Button(action: {
                    auth0Provider.getUserInfo {}
                    updateTripModelItem()
                    ProfileManager.shared.pubShowTripList = false
                    ProfileManager.shared.pubTripPageTitle = isTripEditable ? "Edit saved trip".localized() : "View saved trip"
                }, label: {
                    VStack{
                    Image("btn_edit")
                        .resizable()
                        .frame(width: 30, height: 30, alignment: .center)
                        TextLabel(isTripEditable ? "Edit" : "View", .black, .caption3).foregroundColor(.black)
                    }
                })
                .addAccessibility(text: AvailableAccessibilityItem.editButton.rawValue.localized())
                
                Spacer()
                Divider().background(Color.gray.opacity(0.77))
                Spacer()
                
                if FeatureConfig.shared.isLiveTrackingEnable {
                    Button(action: {
                        MapManager.shared.cleanPlotRoute()
                        MapManager.shared.forceCleanMapReDrawRoute()
                        updateTripModelItem()           // To Update Trip Model Item with Selected Trip
                        var itinerary = item.itinerary
                        itinerary.id = item.id
                        TripPlanningManager.shared.pubPreviousSelectedItinerary = TripPlanningManager.shared.pubSelectedItinerary
                        TripPlanningManager.shared.pubSelectedItinerary = itinerary
                        DispatchQueue.main.async {
                            TripPlanningManager.shared.didSelectItem(itinerary)
                        }
                        if let loginInfo = AppSession.shared.loginInfo {
                            profileManager.isHapticFeedbackOpen = loginInfo.notificationChannel.contains("haptic")
                        }
                        LiveRouteManager.shared.from = CLLocation(latitude: item.from.lat, longitude: item.from.lon)
                        LiveRouteManager.shared.to = CLLocation(latitude: item.to.lat, longitude: item.to.lon)
                        MapManager.shared.isMapSettings = false
						LiveRouteManager.shared.pubIsPreviewMode = false
                        LiveRouteManager.shared.startMonitoringRoute()
                        LiveRouteManager.shared.pubLiveTrackingLoading = true
                        MapManager.shared.pubHideAddressBar = true
                        TabBarMenuManager.shared.currentViewTab = .planTrip
                        TabBarMenuManager.shared.currentItemTab = .planTrip
                        TabBarMenuManager.shared.previousViewTab = .myTrips
                        TabBarMenuManager.shared.previousItemTab = .myTrips
                    }, label: {
                        VStack{
                            Image(systemName: "location.fill.viewfinder")
                                .resizable()
                                .foregroundColor(isTripEditable ? .black : .gray_subtitle_color)
                                .frame(width: 30, height: 30, alignment: .center)
                            TextLabel("Start Trip", .black, .caption3).foregroundColor(isTripEditable ? .black : .gray_subtitle_color)
                        }
                    })
                    .addAccessibility(text: AvailableAccessibilityItem.liveTrackingButton.rawValue.localized())
                    .disabled(!isTripEditable)
                    Spacer()
                    Divider().background(Color.gray.opacity(0.77))
                    Spacer()
                }
				
				Button(action: {
					MapManager.shared.cleanPlotRoute()
					MapManager.shared.forceCleanMapReDrawRoute()
					updateTripModelItem()           // To Update Trip Model Item with Selected Trip
					var itinerary = item.itinerary
					itinerary.id = item.id
					PreviewTripManager.shared.calculateCurrentPreviewSteps(itinerary: itinerary)
                    MapManager.shared.setUserLocationPuckVisible(isTripEditable)
					TripPlanningManager.shared.pubPreviousSelectedItinerary = TripPlanningManager.shared.pubSelectedItinerary
					TripPlanningManager.shared.pubSelectedItinerary = itinerary
					DispatchQueue.main.async {
						TripPlanningManager.shared.didSelectItem(itinerary)
					}
					LiveRouteManager.shared.from = CLLocation(latitude: item.from.lat, longitude: item.from.lon)
					LiveRouteManager.shared.to = CLLocation(latitude: item.to.lat, longitude: item.to.lon)
					MapManager.shared.isMapSettings = false
					LiveRouteManager.shared.pubIsPreviewMode = true
					LiveRouteManager.shared.pubIsRouteActivated = true
					MapManager.shared.pubHideAddressBar = true
					TabBarMenuManager.shared.currentViewTab = .planTrip
					TabBarMenuManager.shared.currentItemTab = .planTrip
					TabBarMenuManager.shared.previousViewTab = .myTrips
					TabBarMenuManager.shared.previousItemTab = .myTrips
				}, label: {
                    VStack{
                        Image(systemName: "map.fill")
                            .resizable()
                            .foregroundColor(Color.black)
                            .frame(width: 30, height: 30, alignment: .center)
                        TextLabel("Preview Trip", .black, .caption3).foregroundColor(.black)
                    }
				})
				.addAccessibility(text: AvailableAccessibilityItem.previewButton.rawValue.localized())
				
				Spacer()
				Divider().background(Color.gray.opacity(0.77))
				Spacer()
                
                Button(action: {
                    AlertManager.shared.presentConfirm(title: "", message: "Would you like to remove this trip?".localized(), primaryButtonText: "Ok".localized(), secondaryButtonText: "Cancel".localized()) { buttonText in
                        if buttonText == "Ok".localized() {
                            self.processing = true
                            self.notificationProvider.removeTripItem(tripId:item.id){ success in
                                DispatchQueue.main.async{
                                    self.processing = false
                                }
                                if success {
                                    ProfileManager.shared.refreshTripList()
                                }else{
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        AlertManager.shared.presentAlert(title: "", message: "Failed to delete the trip item. please try again later".localized())
                                    }
                                }
                            }
                        }
                    }
                }, label: {
                    VStack{
                        Image("btn_delete")
                            .resizable().renderingMode(.template)
                            .foregroundColor(isTripEditable ? .black : .gray_subtitle_color)
                            .frame(width: 30, height: 30, alignment: .center)
                        TextLabel("Delete", .black, .caption3).foregroundColor(isTripEditable ? .black : .gray_subtitle_color)
                    }
				})
                .addAccessibility(text: AvailableAccessibilityItem.deleteButton.rawValue.localized())
                .disabled(!isTripEditable)
                Spacer()
				
            }).padding(.bottom, 5)
        }).background(Color.white).cornerRadius(5).padding(.bottom, 10)
	}
	
    /// Update trip model item
    /// Updates trip model item.
    private func updateTripModelItem(){
        profileManager.selectedTripNotification = item
        var itinerary = item.itinerary
        let itineraries = [itinerary]
        let tripPlan = OTPPlanTrip(itineraries: itineraries)
        profileManager.tripManagerState = .update
        // MARK: Needs to fix it later
        /// needs to change the Type of TripNotificationResponse -> if we changed the type tp SoundTransitGQL -> its not more codable
        profileManager.selectedGraphQLTripPlan = tripPlan
        profileManager.selectedItinerary = itinerary
        profileManager.selectedOldItinerary = item.itinerary
        profileManager.pubPageState = .trips
        ProfileTripModel.shared.updateTripModel(item)
        ProfileTripModel.shared.getRenderData(item: item)
        ProfileTripModel.shared.pubisTripEditable = profileManager.isTripEditable(item)
    }
    /// Check selected trip is editable.
    /// - Parameters:
    ///   - trip: Parameter description
    /// - Returns: Bool
    /// Checks selected trip is editable.
    func checkSelectedTripIsEditable(trip: TripNotificationResponse) -> Bool{
        if let currentUserId = AppSession.shared.loginInfo?.id{
            if trip.userId == currentUserId{
                return true
            }else{
                return false
            }
        }
        return false
    }
	
 /// Weekday description
 /// - Returns: String
 /// Weekday description.
	private func weekdayDescription() -> String {
		var description = ""
		if item.monday {
			if description.count > 0 { description += ", "}
            description += "Mon".localized()
        }
        if item.tuesday {
            if description.count > 0 { description += ", "}
            description += "Tue".localized()
        }
        if item.wednesday {
            if description.count > 0 { description += ", "}
            description += "Wed".localized()
        }
        if item.thursday {
            if description.count > 0 { description += ", "}
            description += "Thu".localized()
        }
        if item.friday {
            if description.count > 0 { description += ", "}
            description += "Fri".localized()
        }
        if item.saturday {
            if description.count > 0 { description += ", "}
            description += "Sat".localized()
        }
        if item.sunday {
            if description.count > 0 { description += ", "}
            description += "Sun".localized()
        }
        if description == "" {
            let startDate = item.itinerary.startTime
            description = Helper.shared.formatTimeIntervaltoFullDate(timeInterval: startDate)
        }
        return description
    }
}

struct SavedTripItemViewAODA: View {
    @Inject var auth0Provider: LoginAuthProvider
    @Inject var notificationProvider: NotificationProvider

    @ObservedObject var profileManager = ProfileManager.shared
    @State var item: TripNotificationResponse
    @Binding var processing: Bool
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        var isTripEditable = profileManager.isTripEditable(item)
        let imageSize = AccessibilityManager.shared.getFontSize()
        return VStack(alignment: .center, spacing: 10, content: {
            VStack(alignment: .leading, spacing: 10){
                HStack {
                    TextLabel("\(item.tripName)", .bold, .title)
                    Spacer()
                }
                HStack
                {
                    TripPlanningManager.shared.SavedTripListTransportsViewAODA(itinerary: item.itinerary, imageSize: imageSize)
                    Spacer()
                }
                
            }.padding(.horizontal,10).padding(.top, 10)
                .addAccessibility(text: "%1, %2".localized(item.tripName,TripPlanningManager.shared.prepareTransportViewString(itinerary: item.itinerary)))
            VStack(alignment: .leading){
                TripPlanningManager.shared.transportsTimeView(itinerary: item.itinerary)
                    .padding(.horizontal, 10)
            }
            HStack{
                VStack{
                    HStack{
                        VStack {
                            Image("ic_origin")
                                .resizable()
                                .frame(width: imageSize, height: imageSize, alignment: .center)
                                .padding(.top, 5)
                            Spacer()
                        }
                        TextLabel("\(item.from.name)",.bold, .body)
                        Spacer()
                    }
                    HStack{
                        VStack {
                            Image("ic_location")
                                .resizable()
                                .frame(width: imageSize, height: imageSize, alignment: .center)
                                .padding(.top, 5)
                            Spacer()
                        }
                        TextLabel("\(item.to.name)",.bold, .body)
                        Spacer()
                    }
                }
            }.padding(.horizontal,10)
                .addAccessibility(text: "From %1 To %2".localized(item.from.name, item.to.name))
            
            HStack{
                VStack {
                    Image("ic_alert")
                        .resizable()
                        .frame(width: imageSize, height: imageSize, alignment: .center)
                        .padding(.top, 5)
                    Spacer()
                }
                
                if item.isActive{
                    VStack{
                        HStack{
                            TextLabel(Helper.shared.formatReadableMins(mins: item.leadTimeInMinutes),.bold, .body)
                            Spacer()
                        }
                        HStack{
                            TextLabel("Before scheduled departure".localized()).foregroundColor(Color.gray_subtitle_color)
                                .font(.body)
                            Spacer()
                        }
                    }
                }
                else{
                    TextLabel("Disabled".localized())
                        .font(.body)
                }
                Spacer()
            }.padding(.horizontal,10)
                .addAccessibility(text: "%1, Before scheduled departure".localized(Helper.shared.formatReadableMins(mins: item.leadTimeInMinutes)))
            
            HStack{
                VStack {
                    Image("ic_schedule")
                        .resizable()
                        .frame(width: imageSize, height: imageSize, alignment: .center)
                        .padding(.top, 5)
                    Spacer()
                }
                TextLabel("\(weekdayDescription())".localized(),.bold, .body)
                Spacer()
            }.padding(.horizontal,10)
                .addAccessibility(text: "%1".localized(weekdayDescription()))
            
            Divider().background(Color.gray.opacity(0.77))
            
            HStack(alignment: .center, spacing:0, content: {
                Group{
                    Spacer()
                    if !(item.isActive) {
                        Button(action: {
                            item.isActive = true
                            updateTripModelItem()
                            ProfileTripModel.shared.storeNotificationToServer(creation: profileManager.tripManagerState.isCreation){ success, errorMessage in }
                        }, label: {
                            Image(systemName: "bell")
                                .resizable()
                                .foregroundColor(isTripEditable ? .black : .gray_subtitle_color)
                                .frame(width: imageSize, height: imageSize, alignment: .center)
                        })
                        .addAccessibility(text: AvailableAccessibilityItem.resumeButton.rawValue.localized())
                    }
                    else{
                        Button(action: {
                            item.isActive = false
                            updateTripModelItem()
                            ProfileTripModel.shared.storeNotificationToServer(creation: profileManager.tripManagerState.isCreation){ success, errorMessage in }
                        }, label: {
                            Image(systemName: "bell.slash")
                                .resizable()
                                .foregroundColor(isTripEditable ? .black : .gray_subtitle_color)
                                .frame(width: imageSize, height: imageSize, alignment: .center)
                        })
                        .addAccessibility(text: AvailableAccessibilityItem.pauseButton.rawValue.localized())
                    }
                    
                    Spacer()
                    Divider().background(Color.gray.opacity(0.77))
                    Spacer()
                }
                .disabled(!isTripEditable)
                Button(action: {
                    auth0Provider.getUserInfo {}
                    updateTripModelItem()
                    ProfileManager.shared.pubShowTripList = false
                    ProfileManager.shared.pubTripPageTitle = isTripEditable ? "Edit saved trip".localized() : "View saved trip"
                }, label: {
                    Image("btn_edit")
                        .resizable()
                        .frame(width: imageSize, height: imageSize, alignment: .center)
                })
                .addAccessibility(text: AvailableAccessibilityItem.editButton.rawValue.localized())
                
                Spacer()
                Divider().background(Color.gray.opacity(0.77))
                Spacer()
                
                if FeatureConfig.shared.isLiveTrackingEnable {
                    Button(action: {
                        MapManager.shared.cleanPlotRoute()
                        MapManager.shared.forceCleanMapReDrawRoute()
                        updateTripModelItem()           // To Update Trip Model Item with Selected Trip
                        var itinerary = item.itinerary
                        itinerary.id = item.id
                        TripPlanningManager.shared.pubPreviousSelectedItinerary = TripPlanningManager.shared.pubSelectedItinerary
                        TripPlanningManager.shared.pubSelectedItinerary = itinerary
                        DispatchQueue.main.async {
                            TripPlanningManager.shared.didSelectItem(itinerary)
                        }
                        if let loginInfo = AppSession.shared.loginInfo {
                            profileManager.isHapticFeedbackOpen = loginInfo.notificationChannel.contains("haptic")
                        }
                        LiveRouteManager.shared.from = CLLocation(latitude: item.from.lat, longitude: item.from.lon)
                        LiveRouteManager.shared.to = CLLocation(latitude: item.to.lat, longitude: item.to.lon)
                        MapManager.shared.isMapSettings = false
                        LiveRouteManager.shared.pubIsPreviewMode = false
                        LiveRouteManager.shared.startMonitoringRoute()
                        LiveRouteManager.shared.pubLiveTrackingLoading = true
                        MapManager.shared.pubHideAddressBar = true
                        TabBarMenuManager.shared.currentViewTab = .planTrip
                        TabBarMenuManager.shared.currentItemTab = .planTrip
                        TabBarMenuManager.shared.previousViewTab = .myTrips
                        TabBarMenuManager.shared.previousItemTab = .myTrips
                    }, label: {
                        Image(systemName: "location.fill.viewfinder")
                            .resizable()
                            .foregroundColor(isTripEditable ? .black : .gray_subtitle_color)
                            .frame(width: imageSize, height: imageSize, alignment: .center)
                    })
                    .addAccessibility(text: AvailableAccessibilityItem.liveTrackingButton.rawValue.localized())
                    .disabled(!isTripEditable)
                    Spacer()
                    Divider().background(Color.gray.opacity(0.77))
                    Spacer()
                }
				
				Button(action: {
                    MapManager.shared.cleanPlotRoute()
                    MapManager.shared.forceCleanMapReDrawRoute()
                    updateTripModelItem()           // To Update Trip Model Item with Selected Trip
                    var itinerary = item.itinerary
                    itinerary.id = item.id
                    PreviewTripManager.shared.calculateCurrentPreviewSteps(itinerary: itinerary)
                    TripPlanningManager.shared.pubPreviousSelectedItinerary = TripPlanningManager.shared.pubSelectedItinerary
                    TripPlanningManager.shared.pubSelectedItinerary = itinerary
                    DispatchQueue.main.async {
                        TripPlanningManager.shared.didSelectItem(itinerary)
                    }
                    LiveRouteManager.shared.from = CLLocation(latitude: item.from.lat, longitude: item.from.lon)
                    LiveRouteManager.shared.to = CLLocation(latitude: item.to.lat, longitude: item.to.lon)
                    MapManager.shared.isMapSettings = false
                    LiveRouteManager.shared.pubIsPreviewMode = true
                    LiveRouteManager.shared.pubIsRouteActivated = true
                    MapManager.shared.pubHideAddressBar = true
                    TabBarMenuManager.shared.currentViewTab = .planTrip
                    TabBarMenuManager.shared.currentItemTab = .planTrip
                    TabBarMenuManager.shared.previousViewTab = .myTrips
                    TabBarMenuManager.shared.previousItemTab = .myTrips
				}, label: {
					Image(systemName: "map.fill")
						.resizable()
						.foregroundColor(Color.black)
						.frame(width: imageSize, height: imageSize, alignment: .center)
				})
				.addAccessibility(text: AvailableAccessibilityItem.previewButton.rawValue.localized())
				
				Spacer()
				Divider().background(Color.gray.opacity(0.77))
				Spacer()
                
                Button(action: {
                    AlertManager.shared.presentConfirm(title: "", message: "Would you like to remove this trip?".localized(), primaryButtonText: "Ok".localized(), secondaryButtonText: "Cancel".localized()) { buttonText in
                        if buttonText == "Ok".localized() {
                            self.processing = true
                            self.notificationProvider.removeTripItem(tripId:item.id){ success in
                                DispatchQueue.main.async{
                                    self.processing = false
                                }
                                if success {
                                    ProfileManager.shared.refreshTripList()
                                }else{
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        AlertManager.shared.presentAlert(title: "", message: "Failed to delete the trip item. please try again later".localized())
                                    }
                                }
                            }
                        }
                    }
                }, label: {
                    Image("btn_delete")
                        .resizable().renderingMode(.template)
                        .foregroundColor(isTripEditable ? .black : .gray_subtitle_color)
                        .frame(width: imageSize, height: imageSize, alignment: .center)
                })
                .addAccessibility(text: AvailableAccessibilityItem.deleteButton.rawValue.localized())
                .disabled(!isTripEditable)
                Spacer()
                
            }).padding(.bottom, 5)
        }).background(Color.white).cornerRadius(5).padding(.bottom, 10)
    }
    
    /// Update trip model item
    /// Updates trip model item.
    private func updateTripModelItem(){
        profileManager.selectedTripNotification = item
        let itinerary = item.itinerary
        let itineraries = [itinerary]
        let tripPlan = OTPPlanTrip(itineraries: itineraries)
        ProfileManager.shared.tripManagerState = .update
        // MARK: Needs to fix it later
        /// needs to change the Type of TripNotificationResponse -> if we changed the type tp SoundTransitGQL -> its not more codable
        ProfileManager.shared.selectedGraphQLTripPlan = tripPlan
        ProfileManager.shared.selectedItinerary = itinerary
        ProfileManager.shared.selectedOldItinerary = item.itinerary
        ProfileManager.shared.pubPageState = .trips
        ProfileTripModel.shared.updateTripModel(item)
        ProfileTripModel.shared.getRenderData(item: item)
        ProfileTripModel.shared.pubisTripEditable = profileManager.isTripEditable(item)
    }
    
    /// Check selected trip is editable.
    /// - Parameters:
    ///   - trip: Parameter description
    /// - Returns: Bool
    func checkSelectedTripIsEditable(trip: TripNotificationResponse) -> Bool{
        if let currentUserId = AppSession.shared.loginInfo?.id{
            if trip.userId == currentUserId{
                return true
            }else{
                return false
            }
        }
        return false
    }
    
    
    /// Weekday description
    /// - Returns: String
    /// Weekday description.
    private func weekdayDescription() -> String {
        var description = ""
        if item.monday {
            if description.count > 0 { description += ", "}
            description += "Mon".localized()
        }
        if item.tuesday {
            if description.count > 0 { description += ", "}
            description += "Tue".localized()
        }
        if item.wednesday {
            if description.count > 0 { description += ", "}
            description += "Wed".localized()
        }
        if item.thursday {
            if description.count > 0 { description += ", "}
            description += "Thu".localized()
        }
        if item.friday {
            if description.count > 0 { description += ", "}
            description += "Fri".localized()
        }
        if item.saturday {
            if description.count > 0 { description += ", "}
            description += "Sat".localized()
        }
        if item.sunday {
            if description.count > 0 { description += ", "}
            description += "Sun".localized()
        }
        return description
    }
}

struct TripListViewer_Previews: PreviewProvider {
    /// Previews.
    /// - Parameters:
    ///   - some: Parameter description
    static var previews: some View {
		TripListViewer()
    }
}
