//
//  HomeView.swift
//

import SwiftUI
import Mapbox

struct HomeView: View {
	@ObservedObject var viewModel = HomeViewModel.shared
	@ObservedObject var envManager = EnvironmentManager.shared
	@ObservedObject var profileManager = ProfileManager.shared
	@ObservedObject var searchSettings = SearchSettings.shared
	@ObservedObject var mapViewModel = MapViewModel.shared
	@ObservedObject var mapManager = MapManager.shared
	@ObservedObject var tripPlanManager = TripPlanningManager.shared
	@ObservedObject var stopViewerModel = StopViewerViewModel.shared
	@ObservedObject var tripViewerModel = TripViewerViewModel.shared
	@ObservedObject var autoCompleteManager = AutoCompleteManager.shared
	@ObservedObject var session = AppSession.shared
	@ObservedObject var alertManager = AlertManager.shared
	@ObservedObject var loginFlowManager = LoginFlowManager.shared
	@ObservedObject var tabBarMenuManager = TabBarMenuManager.shared
	@ObservedObject var searchLocationViewModel = SearchLocationViewModel.shared
	@ObservedObject var mapFromToModel = MapFromToViewModel.shared
	@ObservedObject var tripSettingsViewModel = TripSettingsViewModel.shared
	@ObservedObject var toastManager = ToastManager.shared
	@ObservedObject var routeViewer = RouteViewerModel.shared
	@ObservedObject var env = Env.shared
	@ObservedObject var fareTableViewModel = FareTableManager.shared
	@ObservedObject var indoor = IndoorNavigationManager.shared
	@ObservedObject var helper = Helper.shared
	@ObservedObject var accessibilityManager = AccessibilityManager.shared
	@ObservedObject var liveRouteManager = LiveRouteManager.shared
	@ObservedObject var bottomSlideBarViewModel = BottomSlideBarViewModel.shared
	@ObservedObject var pickerListViewModel = PickerListViewModel.shared
	@ObservedObject var searchManager = SearchManager.shared
	
	@State var zoomLevel = Double(BrandConfig.shared.zoom_level)
	@State private var isPushed = false
	@State private var isSearchPressed = false
	@State private var isCriteriaPicker = false
	@State private var isDatePicker = false
	@State private var isRoutePicker = false
	@State private var loginFlowPageStatus = LoginPageState.login
	
	@Inject var auth0Provider: LoginAuthProvider
	
	@State private var currentHeight: CGFloat = 0
	@State private var minHeight: CGFloat = 130
	@State private var maxHeight: CGFloat = 0
	@State private var fullOpenSlider = false
	@State var showLaunchScreen = true
	@State var defaultText = "Enter destination or choose on map".localized()
	
	var itemDidSelect: ((TripSearchSettingsItem) -> Void)? = nil
	var datePressed: (() -> Void)? = nil
	
	var body: some View {
		return ZStack {
			
			if session.pubDisplaySplashScreen {
				SplashScreen().edgesIgnoringSafeArea(.all).zIndex(999).onAppear {
					DispatchQueue.main.asyncAfter(deadline: .now() + 4) { [self] in
						session.pubDisplaySplashScreen = false
						OTPLog.log(level: .info, info: "time to close the splash screen: \(session.pubDisplaySplashScreen)")
					}
				}
			}
			
			if viewModel.pubOpenSideMenu{
				SideMenuView(menuWidth: accessibilityManager.pubIsLargeFontSize ? ScreenSize.width() : 250)
					.edgesIgnoringSafeArea(.all)
					.zIndex(1001)
					.accessibility(addTraits: [.isModal])
			}
			
			if fareTableViewModel.pubIsShowingFareTable{
				if accessibilityManager.pubIsLargeFontSize{
					FareTableViewAODA()
						.zIndex(1003)
						.accessibility(addTraits: [.isModal])
				}else{
					FareTableView()
						.zIndex(1003)
						.accessibility(addTraits: [.isModal])
				}
			}
			
            if indoor.pubPresentIndoorNavigationView {
                IndoorNavigationView().ignoresSafeArea(.all).zIndex(1004)
            }
            if indoor.pubPresentIndoorNavDialog && !indoor.pubPresentIndoorNavigationView{
                IndoorNavigationDialog().ignoresSafeArea(.all).zIndex(1005)
            }
            if indoor.pubPresentIndoorEntranceDialog && indoor.pubPresentIndoorNavigationView{
                IndoorEntranceDialog().ignoresSafeArea(.all).zIndex(1005)
            }

			VStack(spacing: 0) {
				ZStack {
					// Display the appropriate page based on currentViewTab
					if tabBarMenuManager.currentViewTab == .planTrip {
						PlanTripPageView()
					} else if tabBarMenuManager.currentViewTab == .routes {
						RoutesPageView()
					} else if tabBarMenuManager.currentViewTab == .myTrips {
						MyTripsPageView()
							.zIndex(999)
					}

					// Stop Viewer - Only show when LiveTracking is enabled
					if stopViewerModel.pubIsShowingStopViewer && liveRouteManager.pubIsRouteActivated {
						StopViewerView().edgesIgnoringSafeArea(.all).accessibility(addTraits: [.isModal]).zIndex(2001)
					}

					// Live Tracking View
					if liveRouteManager.pubIsRouteActivated {
						LiveTrackingView().ignoresSafeArea(.all).zIndex(2000)
					}

					// Stop Viewer - When not in LiveTracking
					if stopViewerModel.pubIsShowingStopViewer && !liveRouteManager.pubIsRouteActivated {
						StopViewerView().edgesIgnoringSafeArea(.all).accessibility(addTraits: [.isModal])
					}

					// Trip Time Settings View
					if mapFromToModel.pubIsTimeSettingsExpanded {
						TripTimeSettingsView(dateSelected: { date in
							mapFromToModel.pubIsTimeSettingsExpanded.toggle()
						}, currentDate: searchSettings.date, selectedTimeSetting: searchSettings.pubsSelectedTimeSetting)
						.accessibility(addTraits: [.isModal])
					}

					// Trip Filters View
					if mapFromToModel.pubIsTripFiltersViewExpanded {
						if accessibilityManager.pubIsLargeFontSize {
							TripFiltersViewAODA()
								.accessibility(addTraits: [.isModal])
						} else {
							TripFiltersView()
								.accessibility(addTraits: [.isModal])
						}
					}

					// Accessibility Legend
					if tripPlanManager.pubShowAccessibilityLegend {
						if accessibilityManager.pubIsLargeFontSize {
							AccessibilityLegendViewAODA()
						} else {
							AccessibilityLegendView()
						}
					}

					// Profile Options Popup
					if tabBarMenuManager.pubShowProfilePopUp {
						if accessibilityManager.pubIsLargeFontSize {
							profileOptionsViewerAODA()
								.accessibility(addTraits: [.isModal])
						} else {
							profileOptionsViewer()
								.accessibility(addTraits: [.isModal])
						}
					}

					// Processing View
					if profileManager.pubShowProcessing {
						processingView
					}

					// Offline Dialog
					if env.pubShowOfflineDialog {
						OfflineDialog()
					}
				}
				.zIndex(997)

				// Tab Bar Panel
				if session.loginInfo != nil {
					TabBarPanel().id("login-tabbar-panel").zIndex(999)
				}else{
					TabBarPanel().id("tabbar-panel").zIndex(999)
				}
				
			}
			.edgesIgnoringSafeArea(.all)
			.zIndex(998)
			
			
			
			if profileManager.pubPresentProfilePage {
				ProfileViewer().edgesIgnoringSafeArea(.all).zIndex(999).accessibility(addTraits: [.isModal])
			}
			if tripViewerModel.pubIsShowingTripViewer {
				TripViewerView().edgesIgnoringSafeArea(.all).zIndex(999).accessibility(addTraits: [.isModal])
			}
			
			if tripPlanManager.pubIsShowingTripAlerts {
				TripAlertsView().edgesIgnoringSafeArea(.all).zIndex(999).accessibility(addTraits: [.isModal])
			}
			
			if autoCompleteManager.pubOpenPage {
				SearchViewerView().edgesIgnoringSafeArea(.all).zIndex(1000).accessibility(addTraits: [.isModal])
			}
			
			if loginFlowManager.pubPresentLoginPage {
				LoginViewer().edgesIgnoringSafeArea(.all).zIndex(1002)
					.accessibility(addTraits: [.isModal])
			}
			
            if mapFromToModel.pubShowAdvancedPreferences {
                if AccessibilityManager.shared.pubIsLargeFontSize {
                    AdvancedPreferencesAODAView(dateSelected: { date in
                        mapFromToModel.pubIsTimeSettingsExpanded.toggle()
                    }, selectedTimeSetting: searchSettings.pubsSelectedTimeSetting)
                    .zIndex(1003)
                    .accessibility(addTraits: mapFromToModel.pubShowCloseAlert ? [] : [.isModal])
                } else {
                    AdvancedPreferencesView(dateSelected: { date in
                        mapFromToModel.pubIsTimeSettingsExpanded.toggle()
                    }, selectedTimeSetting: searchSettings.pubsSelectedTimeSetting)
                    .zIndex(1003)
                    .accessibility(addTraits: mapFromToModel.pubShowCloseAlert || mapFromToModel.pubShowAdditionalModesMessage || mapFromToModel.pubShowAccessibleTripMessage ? [] : [.isModal])
                }
            }
			
			if toastManager.pubPresentToastView{
				ToastView().zIndex(1007)
			}
			
			if mapFromToModel.isSettingsExpanded {
				VStack{
					if accessibilityManager.pubIsLargeFontSize {
						if tripSettingsViewModel.isSettingsRequired(){
							TripSettingsViewAODA(itemDidSelect: { item in
								pickerListViewModel.item = item
								pickerListViewModel.loadItem()
								withAnimation{
									tripSettingsViewModel.pubDidItemSelected.toggle()
								}
							}, refreshSettingsDidSelect: {
							})
						}
					} else {
						if tripSettingsViewModel.isSettingsRequired(){
							TripSettingsView(itemDidSelect: { item in
								pickerListViewModel.item = item
								pickerListViewModel.loadItem()
								withAnimation{
									tripSettingsViewModel.pubDidItemSelected.toggle()
								}
								helper.saveUserPreferredSettings()
							}, refreshSettingsDidSelect: {
							})
						}
					}
				}
				.opacity(mapManager.isMapSettings ? 0 : 1.0).zIndex(999)
				.accessibility(addTraits: [.isModal])
				
				
			}
			
			if routeViewer.pubIsPresentRouteFilter {
				VStack{ RouteFilterView() }
					.zIndex(999)
					.accessibility(addTraits: [.isModal])
			}
			
		}
		.padding(0)
		.alert(isPresented: $alertManager.presentAlert) {
			if alertManager.alertType == .alert {
				return Alert(title: Text(alertManager.alertTitle)
					.font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size)),
							 message: Text(alertManager.alertMessage)
					.font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size)),
							 dismissButton: .default(Text("OK".localized())
								.font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size))))
			}
			return Alert(title: Text(alertManager.confirmTitle)
				.font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size)),
						 message: Text(alertManager.confirmMessage)
				.font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size)),
						 primaryButton: .destructive(Text(alertManager.confirmPrimaryButtonText)
							.font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size))) {
								alertManager.confirmCallback?(alertManager.confirmPrimaryButtonText)
							},
						 secondaryButton: .cancel(Text(alertManager.confirmSecondaryButtonText)
							.font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size))){
								alertManager.confirmCallback?(alertManager.confirmSecondaryButtonText)
							})
		}
	}

	// MARK: - Helper Views

	var processingView: some View {
		ZStack {
			VStack {
				HStack {
					Spacer()
				}
				Spacer()
			}.zIndex(998)
				.background(Color.black)
				.opacity(0.5)
			VStack {
				Spacer()
				HStack {
					Spacer()
					VStack {
						Spacer().frame(height: 30)
						TextLabel("Loading...".localized()).font(.footnote).foregroundColor(Color.black).padding(3)
						ActivityIndicator(isAnimating: .constant(true), style: .large)
						Spacer().frame(height: 30)
					}
					.frame(minWidth: 100, minHeight: 100)
					.background(Color.white)
					.foregroundColor(Color.primary)
					.cornerRadius(10)
					Spacer()
				}
				Spacer().frame(height: UIScreen.main.bounds.size.height/2*0.8)
			}.zIndex(999)
		}
		.zIndex(9999)
	}

	func profileOptionsViewer() -> some View {
		var profileName = ""
		if let login = session.loginInfo {
			profileName = login.email
		}

		return ZStack(alignment: .bottom) {
			VStack {
				HStack {
					Spacer()
				}
				Spacer()
			}.edgesIgnoringSafeArea(.all)
				.background(Color.black.opacity(0.8))
				.zIndex(1)
				.onTapGesture(perform: {
					tabBarMenuManager.pubShowProfilePopUp = false
					tabBarMenuManager.currentItemTab = tabBarMenuManager.previousItemTab
					tabBarMenuManager.currentViewTab = tabBarMenuManager.previousViewTab
					tabBarMenuManager.seletedTab = TabBarItem(type: tabBarMenuManager.previousItemTab)
				})

			VStack {
				Spacer()
				VStack {
					HStack(alignment: .center) {
						Spacer()
						TextLabel("Logged in as %1".localized(profileName), .bold, .subheadline)
							.foregroundColor(Color(hex: "#848484"))
							.padding(.top, 10)
							.fixedSize(horizontal: false, vertical: true)
						Spacer()
					}.frame(minHeight: 50)
					Divider()

					Button {
						profileManager.pubShowProcessing = true
						tabBarMenuManager.pubShowProfilePopUp = false
						auth0Provider.getUserInfo {
							DispatchQueue.main.async {
								profileManager.pubShowProcessing = false
								if let userInfo = session.loginInfo, userInfo.emailIsVerified {
									profileManager.isEmailOpen = userInfo.notificationChannel.contains("email")
									profileManager.isSMSOpen = userInfo.notificationChannel.contains("sms")
									profileManager.isPushNotificationOpen = userInfo.notificationChannel.contains("push")
									profileManager.isHapticFeedbackOpen = userInfo.notificationChannel.contains("haptic")
									profileManager.pubPresentProfilePage = true
									tabBarMenuManager.currentItemTab = .planTrip
									tabBarMenuManager.currentViewTab = .planTrip
								} else {
									loginFlowManager.pageState = .verifyEmail
									loginFlowManager.pubPresentLoginPage = true
								}
							}
						}
					} label: {
						Spacer()
						TextLabel("My Settings".localized(), .bold, .body)
							.foregroundColor(.black)
							.fixedSize(horizontal: false, vertical: true)
						Spacer()
					}
					Divider()

					Button {
						if let url = URL(string: FeatureConfig.shared.help_url) {
							UIApplication.shared.open(url)
						}
					} label: {
						Spacer()
						TextLabel("Help".localized(), .bold, .body).foregroundColor(.black)
						Spacer()
					}
					Divider()

					Button {
						mapFromToModel.resetAction()
						resetPageStatus()
						session.logout()
						loginFlowManager.removeSkip()
						tabBarMenuManager.currentItemTab = tabBarMenuManager.previousItemTab
						tabBarMenuManager.currentViewTab = tabBarMenuManager.previousViewTab
						tabBarMenuManager.seletedTab = TabBarItem(type: tabBarMenuManager.currentItemTab)
					} label: {
						Spacer()
						TextLabel("Sign out".localized(), .bold, .body).foregroundColor(Color(hex: "#BC1919"))
						Spacer()
					}
					Divider()
				}
				.background(Color.white)
				.clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight])).shadow(color: Color.shadow, radius: 10)
				.frame(maxHeight: ScreenSize.height() * 0.6, alignment: .bottom)
			}.zIndex(2)
		}
		.edgesIgnoringSafeArea(.all)
	}

	func profileOptionsViewerAODA() -> some View {
		var profileName = ""
		if let login = session.loginInfo {
			profileName = login.email
		}
		return VStack {
			Spacer().frame(height: ScreenSize.safeTop() + 10)
			ScrollView {
				VStack{
					HStack(alignment: .center){
						Spacer()
						TextLabel("Logged in as %1".localized(profileName), .bold, .subheadline)
							.foregroundColor(Color(hex: "#848484"))
							.padding(.top, 10)
							.fixedSize(horizontal: false, vertical: true)
						Spacer()
					}.frame(minHeight: 50)
					Divider()
					
					Button {
						profileManager.pubShowProcessing = true
						tabBarMenuManager.pubShowProfilePopUp = false
						auth0Provider.getUserInfo {
							DispatchQueue.main.async {
								profileManager.pubShowProcessing = false
								if let userInfo = session.loginInfo, userInfo.emailIsVerified {
									profileManager.isEmailOpen = userInfo.notificationChannel.contains("email")
									profileManager.isSMSOpen = userInfo.notificationChannel.contains("sms")
									profileManager.isPushNotificationOpen = userInfo.notificationChannel.contains("push")
                                    profileManager.isHapticFeedbackOpen = userInfo.notificationChannel.contains("haptic")
									profileManager.pubPresentProfilePage = true
									tabBarMenuManager.currentItemTab = .planTrip
									tabBarMenuManager.currentViewTab = .planTrip
								} else {
									loginFlowManager.pageState = .verifyEmail
									loginFlowManager.pubPresentLoginPage = true
								}
							}
						}
					} label: {
						Image("settings_icon")
							.resizable()
							.frame(width: accessibilityManager.getFontSize(), height: accessibilityManager.getFontSize(), alignment: .center)
						Spacer().frame(width: 20)
						TextLabel("My Settings".localized(), .bold, .body)
							.foregroundColor(.black)
							.multilineTextAlignment(.leading)
							.fixedSize(horizontal: false, vertical: true)
						Spacer()
					}
					.padding(.horizontal)
					
					Button {
                        if let url = URL(string: FeatureConfig.shared.help_url) {
							UIApplication.shared.open(url)
						}
					} label: {
						Image("ic_help")
							.resizable()
							.frame(width: accessibilityManager.getFontSize(), height: accessibilityManager.getFontSize(), alignment: .center)
						Spacer().frame(width: 20)
						TextLabel("Help".localized(),.bold, .body).foregroundColor(.black)
						Spacer()
					}
					.padding(.horizontal)
					
					Button {
						mapFromToModel.resetAction()
						resetPageStatus()
						session.logout()
						loginFlowManager.removeSkip()
						tabBarMenuManager.currentItemTab = tabBarMenuManager.previousItemTab
						tabBarMenuManager.currentViewTab = tabBarMenuManager.previousViewTab
						tabBarMenuManager.seletedTab = TabBarItem(type: tabBarMenuManager.currentItemTab)
					} label: {
						Image("ic_logout")
							.resizable()
							.frame(width: accessibilityManager.getFontSize(), height: accessibilityManager.getFontSize(), alignment: .center)
						Spacer().frame(width: 20)
						TextLabel("Sign out".localized(), .bold, .body).foregroundColor(Color(hex: "#BC1919"))
						Spacer()
					}
					.padding(.horizontal)
					Spacer()
				}
			}
		}
		.background(Color.white)
	}
	
 /// Reset page status
 /// Resets page status.
	private func resetPageStatus(){
		mapManager.cleanPlotRoute()
		mapManager.mapSize = .full
	}
	
 /// Expand button.
 /// - Parameters:
 ///   - some: Parameter description
	private var expandButton: some View {
		Button(action: {
			mapManager.mapSize = mapManager.mapSize == .full ? .half : .full
		}) {
			HStack {
				Image(mapManager.mapSize == .full ? "showResults_icon" : "expand_icon" )
					.resizable()
					.frame(width: 20, height: 20)
					.padding(.horizontal, 5)
				TextLabel(mapManager.mapSize == .full ? "Show Results".localized() : "Expand map".localized()).fixedSize(horizontal: true, vertical: false)
					.padding(.trailing, 5)
					.foregroundColor(Color.black)
				
			}
		}
		.frame(width: 145, height: 35)
		.background(Color.white)
	}
	
 /// Trip planning view.
 /// - Parameters:
 ///   - some: Parameter description
	private var tripPlanningView: some View {
		var tripView = TripPlanningView()
		
		tripView.showDetailsAction = { groupEntry, selectedItinerary in
			mapManager.removePreviewFromMarker()
			mapManager.removePreviewToMarker()
			tripPlanManager.pubSelectedGroupEntry = groupEntry
			tripPlanManager.pubSelectedItinerary = selectedItinerary
			mapManager.pubSearchRoute = true
		}
		
		tripView.selectedItinerary = { itinerary in
			viewModel.didSelect(itinerary: itinerary)
			bottomSlideBarViewModel.pubIsDraggable = true
			let viewArea = ViewArea(topRight: CGPoint(x:UIScreen.main.bounds.width,y:0), bottomLeft: CGPoint(x:0, y:helper.getDeafultViewHeight(heightPosition: .bottom)))
			let edgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 20)
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
				mapManager.setCenterArea(viewArea: viewArea, mapViewHeight: helper.getDefaultMapViewHeight(), mapViewWidth: UIScreen.main.bounds.width,edgeInset: edgeInsets)
			})
		}
		tripView.stopViewerAction = { itinerary, leg in
			let stopId = tripPlanManager.stopDisplayIdentifier(leg: leg)
			stopViewerModel.stop = mapManager.stops.first(where: { $0.id == stopId})
			stopViewerModel.itinerary = itinerary
			stopViewerModel.itineraryStop = leg
            stopViewerModel.getGraphQLStopTimes()
            stopViewerModel.getGraphQLStopSchedules()
			stopViewerModel.pubStopViewerOrigin = .tripDetail
			stopViewerModel.addStopMarker()
			stopViewerModel.pubIsShowingStopViewer = true
			stopViewerModel.pubKeepShowingStopViewer = true
		}
		
		tripView.tripViewerAction = { itinerary, leg in
			tripViewerModel.pubIsShowingTripViewer = true
		}
		tripView.backAction = {
			
			mapManager.pubIsInTripPlan = false
			mapManager.pubHideAddressBar = false
			mapManager.cleanPlotRoute()
			mapManager.reDrawFromToMarkers()
		}
		
		return tripView
			.foregroundColor(Color.blue)
			.background(Color.main)
			.accessibilityAddTraits([.isModal])
		
	}
	
 /// Graph q l trip plan detail view.
 /// - Parameters:
 ///   - some: Parameter description
	private var graphQLTripPlanDetailView: some View {
		VStack {
			TripPlanDetailView(sortOption: tripPlanManager.pubSortOption,
							   backAction: {
				profileManager.clearSelectedTripInfo()
				mapManager.pubIsInTripPlanDetail = false
				withAnimation {
					mapManager.pubIsInTripPlan = true
				}
			}, stopViewerAction: { itinerary, leg in
				let stopId = tripPlanManager.stopDisplayIdentifier(leg: leg)
				stopViewerModel.stop = mapManager.stops.first(where: { $0.id == stopId})
				stopViewerModel.itinerary = itinerary
				stopViewerModel.itineraryStop = leg
                stopViewerModel.getGraphQLStopTimes()
                stopViewerModel.getGraphQLStopSchedules()
				stopViewerModel.pubStopViewerOrigin = .tripDetail
				stopViewerModel.addStopMarker()
				stopViewerModel.pubIsShowingStopViewer = true
				stopViewerModel.pubKeepShowingStopViewer = true
			}, tripViewerAction: { itinerary, leg in
				tripViewerModel.itinerary = itinerary
				tripViewerModel.itineraryStop = leg
				tripViewerModel.pubIsShowingTripViewer = true
			})
		}
	}
	
	
	
 /// Update view
 /// Updates view.
	private func updateView() {
		withAnimation {
			mapManager.isMapSettings = false
		}
	}
	
    /// Map settings view.
    /// - Parameters:
    ///   - some: Parameter description
    private var mapSettingsView: some View {
        VStack{
            if !liveRouteManager.pubIsRouteActivated {
                ZStack(alignment: .topLeading) {
                    VStack{
                        HStack {
                            if mapManager.pubIsInTripPlanDetail{
                                if tripPlanManager.pubSaveTripText != "Cannot Save" {
                                    favouriteButton.addAccessibility(text: AvailableAccessibilityItem.favouriteButton.rawValue.localized())
                                }
                            }else{
                                if JMapManager.shared.pubIsNearByVenue{
                                    iNSButton.addAccessibility(text: "Go to Indoor Navigation Button")
                                }
                            }
                            
                            Spacer()
                            if !mapManager.isSearchingPlace{
                                mapLayerView()
                                    .addAccessibility(text: AvailableAccessibilityItem.mapLayerButton.rawValue.localized())
                            }
                        }
                        Spacer().frame(height: 20)
                        HStack{
                            if mapManager.pubIsInTripPlanDetail && JMapManager.shared.pubIsNearByVenue {
                                iNSButton.addAccessibility(text: "Go to Indoor Navigation Button")
                            }
                            Spacer()
                        }
                    }
                }
            }else{
                HStack{
                    if JMapManager.shared.pubIsNearByVenue {
                        iNSButton.addAccessibility(text: "Go to Indoor Navigation Button")
                    }
                    Spacer()
                }
            }
        }
    }

	
 /// Favourite button.
 /// - Parameters:
 ///   - some: Parameter description
	private var favouriteButton: some View {
		HStack{
			Button(action: {
				profileManager.pubShowProcessing = true
				auth0Provider.getUserInfo {
					DispatchQueue.main.async {
						profileManager.pubShowProcessing = false
						if let _ = session.loginInfo {
							if loginFlowManager.pageState == .verifyEmail ||
								loginFlowManager.pageState == .launchSetup {
								loginFlowManager.pubPresentLoginPage = true
							}else{
								profileManager.pubPageState = .trips
                                ProfileTripModel.shared.pubIsTripNameEmpty = false
								profileManager.pubShowTripList = false
								profileManager.pubEditTripFromPlanTrip = true
								tabBarMenuManager.currentViewTab = .myTrips
								tabBarMenuManager.currentItemTab = .planTrip
								profileManager.pubTripPageTitle = "Save new trip".localized()
                                ProfileTripModel.shared.pubisTripEditable = true
                                ProfileTripModel.shared.pubCompanionDropdownItem = TravelCompanionsViewModel.shared.getCompanionList()
                                ProfileTripModel.shared.pubObserversDropdownitem = TravelCompanionsViewModel.shared.getCompanionList()
							}
						}else{
							loginFlowManager.pageState = .login
							loginFlowManager.pubPresentLoginPage = true
						}
					}
				}
			}) {
				Image(systemName: "star")
					.renderingMode(.template)
					.resizable()
					.foregroundColor(Color.black)
					.frame(width: 20, height: 20)
			}
		}        .frame(width: 48, height: 48)
			.background(Color.white)
			.clipShape(Circle())
			.padding(.leading, 20)
			.shadow(radius: 5)
	}
    
    /// I n s button.
    /// - Parameters:
    ///   - some: Parameter description
    private var iNSButton: some View {
        HStack{
            Button(action: {
                IndoorNavigationManager.shared.pubPresentIndoorNavigationView = true
                if let loginInfo = AppSession.shared.loginInfo {
                    ProfileManager.shared.isHapticFeedbackOpen = loginInfo.notificationChannel.contains("haptic")
                }
                JMapManager.shared.startUniversalTimer()
                if LiveRouteManager.shared.pubIsRouteActivated {
                    // If we are in the activated route mode, then, we disable it
                    LiveRouteManager.shared.resetLiveTracking()
                }
            }) {
                Image("ic_building")
                    .resizable()
            }
        } .frame(width: 48, height: 48)
            .clipShape(Circle())
            .padding(.leading, 20)
            .shadow(radius: 5)
    }

	
 /// Map layer options.
 /// - Parameters:
 ///   - some: Parameter description
	private var mapLayerOptions: some View {
		MapSettingsView()
	}
	
 /// Locate me view.
 /// - Parameters:
 ///   - some: Parameter description
	private var locateMeView: some View {
		VStack{
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
			
		}.frame(width: 48, height: 48)
			.background(mapManager.isLocateMe ?  Color.main : Color.white)
			.clipShape(Circle())
			.padding(.trailing)
			.shadow(radius: 5)
	}
	
 /// App logo view.
 /// - Parameters:
 ///   - some: Parameter description
	private var appLogoView: some View {
		Image("customer_logo_icon")
			.resizable()
			.foregroundColor(.white)
			.aspectRatio(contentMode: .fit)
			.frame(width: 30, height: 30, alignment: .center)
			.padding(UIScreen.main.bounds.width/4 + 15)
	}
}

struct HomeView_Previews: PreviewProvider {
 /// Previews.
 /// - Parameters:
 ///   - some: Parameter description
	static var previews: some View {
		HomeView()
	}
}
