//
//  PlanTripPageView.swift
//

import SwiftUI

/// Plan Trip page view that displays the map and trip planning interface.
/// This view is shown when the Plan Trip tab is selected.
struct PlanTripPageView: View {
	@ObservedObject var viewModel = HomeViewModel.shared
	@ObservedObject var mapViewModel = MapViewModel.shared
	@ObservedObject var mapManager = MapManager.shared
	@ObservedObject var tripPlanManager = TripPlanningManager.shared
	@ObservedObject var stopViewerModel = StopViewerViewModel.shared
	@ObservedObject var tripViewerModel = TripViewerViewModel.shared
	@ObservedObject var searchSettings = SearchSettings.shared
	@ObservedObject var mapFromToModel = MapFromToViewModel.shared
	@ObservedObject var tripSettingsViewModel = TripSettingsViewModel.shared
	@ObservedObject var helper = Helper.shared
	@ObservedObject var accessibilityManager = AccessibilityManager.shared
	@ObservedObject var envManager = EnvironmentManager.shared
	@ObservedObject var liveRouteManager = LiveRouteManager.shared
	@ObservedObject var bottomSlideBarViewModel = BottomSlideBarViewModel.shared
	@ObservedObject var profileManager = ProfileManager.shared
	@ObservedObject var session = AppSession.shared
	@ObservedObject var loginFlowManager = LoginFlowManager.shared
	@ObservedObject var tabBarMenuManager = TabBarMenuManager.shared

	@Inject var auth0Provider: LoginAuthProvider

	@State private var isSearchPressed = false
	@State var defaultText = "Enter destination or choose on map".localized()

	let bottomSliderMinRatio = 0.15

	var body: some View {
		GeometryReader { geometry in
			ZStack {
				ZStack(alignment: .topTrailing) {
					ZStack {
						if !(stopViewerModel.pubIsShowingStopViewer) &&
							!(tripViewerModel.pubIsShowingTripViewer)
						{
							VStack(spacing: 0) {
								if liveRouteManager.pubIsRouteActivated && liveRouteManager.pubIsPreviewMode {
									HStack(){}.frame(height: ScreenSize.safeTop()).padding(0)
									HStack {
										Spacer()
										Text("Preview Trip").font(.system(size: 25)).bold()
										Spacer()
									}
									.frame(height: 60)
									.padding(0)
								}
								mapManager.map()
									.edgesIgnoringSafeArea(.all)
									.accessibility(hidden: true)
									.frame(width: (liveRouteManager.pubIsRouteActivated && liveRouteManager.pubIsPreviewMode) ? UIScreen.main.bounds.size.width - 20 : UIScreen.main.bounds.size.width, height: helper.getDefaultMapViewHeight())
									.border((liveRouteManager.pubIsRouteActivated && liveRouteManager.pubIsPreviewMode) ? Color.gray : Color.clear, width: 1)
									.onAppear {
										mapManager.udateCompassPosition(newPosition: mapManager.pubIsInTripPlan && !tripPlanManager.pubIsLoading ? CGPoint(x: 15, y: 60) : CGPoint(x: 15, y: 20))
									}
							}
						}
					}

					VStack {
						Spacer().frame(height: ScreenSize.safeTop())
						ZStack {
							VStack {
								fromToView()
									.padding(.horizontal, 20)
									.padding(.bottom, 10)
								mapSettingsView
								Spacer()
								if accessibilityManager.pubIsLargeFontSize {
									Spacer().frame(height: 70)
								}
							}
						}
					}
					.background(Color.clear)
					.edgesIgnoringSafeArea(.bottom)

					if mapManager.isMapSettings {
						VStack {
							BottomSlideBarView(minHeight: 240, maxHeight: 240, enableDrag: false, isFullScreen: false, currentOffsetY: -100, enableCloseIndicator: true) {
								mapLayerOptions
							}.opacity(mapManager.isMapSettings ? 1.0 : 0)
						}
					} else {
						if !liveRouteManager.pubIsRouteActivated {
							VStack {
								Spacer()
								HStack {
									Spacer()
									if !mapManager.isSearchingPlace {
										locateMeView
											.addAccessibility(text: AvailableAccessibilityItem.locateMe.rawValue.localized())
											.accessibility(hidden: mapManager.pubIsInTripPlan)
									}
								}
								.padding(.bottom)
							}
						}
					}
				}
				.zIndex(998)

				if !mapManager.isMapSettings {
					if mapManager.pubIsInTripPlan {
						LoadingView(isShowing: $tripPlanManager.pubIsLoading) {
							GeometryReader { reader in
								VStack {
									if !tripPlanManager.pubIsLoading {
										if !liveRouteManager.pubIsRouteActivated {
											if mapManager.pubIsInTripPlanDetail {
												BottomSlideBarView(minHeight: reader.size.height * bottomSliderMinRatio, maxHeight: reader.size.height * 0.76, enableDrag: true, isFullScreen: false, currentOffsetY: accessibilityManager.pubIsLargeFontSize ? -(reader.size.height * 0.76)/3 : bottomSlideBarViewModel.lastOffset, enableCloseIndicator: false) {
													graphQLTripPlanDetailView
														.allowsHitTesting(!envManager.accessibilityEnabled)
												}.opacity(mapManager.isMapSettings ? 0 : 1.0)
											} else {
												BottomSlideBarView(minHeight: 0, maxHeight: 0, enableDrag: false, isFullScreen: true, currentOffsetY: 0, enableCloseIndicator: false) {
													tripPlanningView
												}.opacity(mapManager.isMapSettings ? 0 : 1.0)
											}
										}
									}
								}
								.ignoresSafeArea()
								.onAppear {
									let viewArea = ViewArea(topRight: CGPoint(x: UIScreen.main.bounds.width, y: 0), bottomLeft: CGPoint(x: 0, y: helper.getDeafultViewHeight(heightPosition: .bottom)))
									let edgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 20)
									DispatchQueue.main.asyncAfter(deadline: .now() + 1.1, execute: {
										mapManager.setCenterArea(viewArea: viewArea, mapViewHeight: helper.getDefaultMapViewHeight(), mapViewWidth: UIScreen.main.bounds.width, edgeInset: edgeInsets)
									})
								}
							}
						}
					}
				}
			}
			.edgesIgnoringSafeArea(.all)
		}
	}

	// MARK: - Helper Views

	private func fromToView() -> some View {
		let mapFromToView: MapFromToView = MapFromToView(
			settings: searchSettings,
			iconName: "map_to_icon",
			defaultTextfieldText: defaultText,
			isSearchPressed: self.$isSearchPressed)
		return mapFromToView
	}

	private var mapSettingsView: some View {
		VStack {
			if !liveRouteManager.pubIsRouteActivated {
				ZStack(alignment: .topLeading) {
					VStack {
						HStack {
							if mapManager.pubIsInTripPlanDetail {
								if tripPlanManager.pubSaveTripText != "Cannot Save" {
									favouriteButton.addAccessibility(text: AvailableAccessibilityItem.favouriteButton.rawValue.localized())
								}
							} else {
								if JMapManager.shared.pubIsNearByVenue {
									iNSButton.addAccessibility(text: "Go to Indoor Navigation Button")
								}
							}

							Spacer()
							if !mapManager.isSearchingPlace {
								mapLayerView()
									.addAccessibility(text: AvailableAccessibilityItem.mapLayerButton.rawValue.localized())
							}
						}
						Spacer().frame(height: 20)
						HStack {
							if mapManager.pubIsInTripPlanDetail && JMapManager.shared.pubIsNearByVenue {
								iNSButton.addAccessibility(text: "Go to Indoor Navigation Button")
							}
							Spacer()
						}
					}
				}
			} else {
				HStack {
					if JMapManager.shared.pubIsNearByVenue {
						iNSButton.addAccessibility(text: "Go to Indoor Navigation Button")
					}
					Spacer()
				}
			}
		}
	}

	private var favouriteButton: some View {
		HStack {
			Button(action: {
				profileManager.pubShowProcessing = true
				auth0Provider.getUserInfo {
					DispatchQueue.main.async {
						profileManager.pubShowProcessing = false
						if let _ = session.loginInfo {
							if loginFlowManager.pageState == .verifyEmail ||
								loginFlowManager.pageState == .launchSetup {
								loginFlowManager.pubPresentLoginPage = true
							} else {
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
						} else {
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
		}.frame(width: 48, height: 48)
			.background(Color.white)
			.clipShape(Circle())
			.padding(.leading, 20)
			.shadow(radius: 5)
	}

	private var iNSButton: some View {
		HStack {
			Button(action: {
				IndoorNavigationManager.shared.pubPresentIndoorNavigationView = true
				if let loginInfo = AppSession.shared.loginInfo {
					ProfileManager.shared.isHapticFeedbackOpen = loginInfo.notificationChannel.contains("haptic")
				}
				JMapManager.shared.startUniversalTimer()
				if LiveRouteManager.shared.pubIsRouteActivated {
					LiveRouteManager.shared.resetLiveTracking()
				}
			}) {
				Image("ic_building")
					.resizable()
			}
		}.frame(width: 48, height: 48)
			.clipShape(Circle())
			.padding(.leading, 20)
			.shadow(radius: 5)
	}

	private var mapLayerOptions: some View {
		MapSettingsView()
	}

	private var locateMeView: some View {
		VStack {
			Button(action: {
				withAnimation {
					mapManager.followMe(enable: !mapManager.isLocateMe)
				}
			}) {
				Image("map_locateme_icon")
					.resizable()
					.renderingMode(.template)
					.foregroundColor(mapManager.isLocateMe ? .white : .gray)
					.frame(width: 30, height: 30, alignment: .center)
			}
		}.frame(width: 48, height: 48)
			.background(mapManager.isLocateMe ? Color.main : Color.white)
			.clipShape(Circle())
			.padding(.trailing)
			.shadow(radius: 5)
	}

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
			let viewArea = ViewArea(topRight: CGPoint(x: UIScreen.main.bounds.width, y: 0), bottomLeft: CGPoint(x: 0, y: helper.getDeafultViewHeight(heightPosition: .bottom)))
			let edgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 20)
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
				mapManager.setCenterArea(viewArea: viewArea, mapViewHeight: helper.getDefaultMapViewHeight(), mapViewWidth: UIScreen.main.bounds.width, edgeInset: edgeInsets)
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

	private func mapLayerView() -> some View {
		Button(action: {
			withAnimation {
				mapManager.isMapSettings.toggle()
			}
		}) {
			Image("map_layer_icon")
				.resizable()
				.renderingMode(.template)
				.foregroundColor(Color.black)
				.frame(width: 20, height: 20)
		}
		.frame(width: 48, height: 48)
		.background(Color.white)
		.clipShape(Circle())
		.padding(.trailing, 20)
		.shadow(radius: 5)
	}
}
