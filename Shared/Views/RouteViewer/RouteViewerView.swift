//
//  RouteViewerView.swift
//

import SwiftUI
import Combine

struct RouteViewerView: View {
    @ObservedObject var envManager = EnvironmentManager.shared
    @ObservedObject var routeViewer = RouteViewerModel.shared
	@ObservedObject var autoCompleteManager = AutoCompleteManager.shared
    @ObservedObject var mapManager = MapManager.shared
    @ObservedObject var loginFlowManager = LoginFlowManager.shared
    @ObservedObject var stopViewer = StopViewerViewModel.shared
    @ObservedObject var tabBarMenuManager = TabBarMenuManager.shared
    @ObservedObject var bottomSliderBarModel = BottomSlideBarViewModel.shared
    @State private var isMapSettings = false
    @State private var isViewNextArrivals = true
    @State private var isMenuShown = false
	let bottomSliderMinRatio = 0.15
    /// Map layer option height offset.
    /// - Parameters:
    ///   - Double: Parameter description
    var mapLayerOptionHeightOffset:Double {
        get{
            return bottomSliderMinRatio == 0.5 ? 450 : 450
        }
    }
    @State private var contentSize = CGSize.zero
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
                if !stopViewer.pubIsShowingStopViewer && tabBarMenuManager.currentItemTab == .routes{
                    GeometryReader { geo in
                        mapManager.map()
                            .edgesIgnoringSafeArea(.all).accessibility(hidden:  true)
                            .onAppear(){
                                bottomSliderBarModel.pubBottomSlideBarPosition = .bottom
                                let viewArea = ViewArea(topRight: CGPoint(x:UIScreen.main.bounds.width,y:0), bottomLeft: CGPoint(x:0, y:Helper.shared.getDeafultViewHeight(heightPosition: bottomSliderBarModel.pubBottomSlideBarPosition)))
                                let edgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 20)
                                MapManager.shared.setCenterArea(viewArea: viewArea, mapViewHeight: Helper.shared.getDefaultMapViewHeight(), mapViewWidth: UIScreen.main.bounds.width, edgeInset: edgeInsets)
                            mapManager.udateCompassPosition(newPosition: CGPoint(x: 15, y: 25))
                        }
                    }.edgesIgnoringSafeArea(.all)
                }
				
                VStack {
                    Spacer().frame(height:ScreenSize.safeTop())
                    if routeViewer.pubHideSearchBar{
                        CollapsedSearchBarView(hideAddressBar: routeViewer.pubHideSearchBar) {
                            autoCompleteManager.pubFilterKeywordForRoute = ""
                            autoCompleteManager.pubFilteredItems.removeAll()
                            mapManager.cleanPlotRoute()
                            mapManager.deSelectAnnotations()
                            RouteManager.shared.selectedRoute = nil
                            mapManager.routePlotItems = nil
                            mapManager.removeRealTimeBusMarker()
                            routeViewer.pubHideSearchBar = false
                            routeViewer.refreshRouteItems()
                        } collapseAction: {
                            withAnimation(.easeIn(duration: 0.1)) {
                                routeViewer.pubHideSearchBar.toggle()
                            }
                        }.padding(.horizontal, 20)
                    }
                    else{
                        ZStack{
                            HStack {
                                LocationTextField(placeholder: "Find A Route".localized(), lineColor: Color.black, imageName: "icon_search", resize: 35,
                                                  treatAsButton: true,
                                                  leadingPadding: 20, imageOnTap: {
                                    onTapSearch()
                                }, text: self.$autoCompleteManager.pubFilterKeywordForRoute)
                                .background(Color.white)
                                .overlay(
                                    GeometryReader { geo in
                                        Color.clear.onAppear {
                                            contentSize = geo.size
                                        }
                                    }
                                )
                                .addAccessibility(text: AvailableAccessibilityItem.searchRouteTextField.rawValue.localized())
                                .zIndex(1)
                                .accessibilityElement(children: AccessibilityHandler.shared.hideAccessibility(.tabBar) ? .ignore : .contain)
                                .onTapGesture {
                                    onTapSearch()
                                }
                                Spacer()
                                collapseButton.padding(.trailing, 10)
                            }
                            .frame(minHeight: 50)
                            .background(Color.white)
                            .clipShape(RoundedCorner(radius: 10, corners: .allCorners))
                            .shadow(radius: 5)
                            
                            if RouteFilterPickerListViewModel.shared.pubIsAgencyValueChanged || RouteFilterPickerListViewModel.shared.pubIsModeValueChanged {
                                HStack{
                                    Circle().fill(Color.green).frame(width: 10, height: 10, alignment: .center).offset(x: AccessibilityManager.shared.pubIsLargeFontSize ? -1 : 0, y: AccessibilityManager.shared.pubIsLargeFontSize ? -(contentSize.height / 2) :-25)
                                    Spacer()
                                }.zIndex(9999)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                    }
                    mapSettingsView
                    Spacer()
                }.availableAccessibility(AvailableAccessibilityItem.routesSearchBar)
                .background(Color.clear)
                .edgesIgnoringSafeArea(.bottom)
                
                if mapManager.isMapSettings {
                    VStack{
                        Spacer()
                        BottomSlideBarView(minHeight: 235, maxHeight: 235, enableDrag: false, isFullScreen: false, currentOffsetY: -100, enableCloseIndicator: true){
                            mapLayerOptions
                                .availableAccessibility(AvailableAccessibilityItem.mapLayerView)
                        }
                    }
                }else{
                    BottomSlideBarView(minHeight: geometry.size.height * bottomSliderMinRatio, maxHeight: geometry.size.height * 0.76, enableDrag: true, isFullScreen: false, currentOffsetY: BottomSlideBarViewModel.shared.lastOffset, enableCloseIndicator: false) {
                        routeListView.background(Color.white)
                            .allowsHitTesting(!envManager.accessibilityEnabled)
                            .availableAccessibility(AvailableAccessibilityItem.routesListView)
                    }
                }
            }
            .onAppear(perform: {
                StopViewerViewModel.shared.pubIsShowingStopViewer = false
                BottomSlideBarViewModel.shared.pubIsDraggable = true
                BottomSlideBarViewModel.shared.isSliderFullOpen = false
                if let route = RouteManager.shared.selectedRoute{
                    MapManager.shared.removeRealTimeBusMarker()
                    RouteManager.shared.getRouteDetails(route: route)
                    RouteManager.shared.getRealtimeBusData(route: route, pattern: nil)
                }
            })
            .onDisappear {
                mapManager.removeRealTimeBusMarker()
            }
		}
    }
    
    /// On tap search
    /// Handles tap search.
    func onTapSearch() {
        autoCompleteManager.pubFilterKeywordForRoute = ""
        AutoCompleteManager.shared.placeholder = "Find A Route".localized()
        AutoCompleteManager.shared.textImageName = "icon_search"
        AutoCompleteManager.shared.autoCompleteMode = .route
        AutoCompleteManager.shared.pubOpenPage = true
        let keywords = autoCompleteManager.pubFilterKeywordForRoute
        routeViewer.pubHideSearchBar = true
        self.autoCompleteManager.loadSections(keywords: keywords)
    }
    
    /// Collapse button.
    /// - Parameters:
    ///   - some: Parameter description
    private var collapseButton: some View{
        Button {
            withAnimation(.easeIn(duration: 0.1)) {
                routeViewer.pubHideSearchBar.toggle()
            }
        } label: {
            Image(routeViewer.pubHideSearchBar ? "btn_expand" : "btn_collapse")
                .renderingMode(.template)
                .resizable()
                .foregroundColor(.black)
                .frame(width: AccessibilityManager.shared.pubIsLargeFontSize ? 68 : 38, height: AccessibilityManager.shared.pubIsLargeFontSize ? 68 : 38, alignment: .center)
                
        }.background(Color.clear)
            .addAccessibility(text: (mapManager.pubHideAddressBar ? AvailableAccessibilityItem.expandButton.rawValue.localized() : AvailableAccessibilityItem.collapseButton.rawValue.localized()))
    }
    
    /// Route list view.
    /// - Parameters:
    ///   - some: Parameter description
    private var routeListView: some View {
		
		return ScrollView {
					ScrollViewReader { proxy in
						LazyVStack(alignment: .leading) {
							ForEach(0..<routeViewer.pubRouteItems.count, id: \.self) { index in
                                if AccessibilityManager.shared.pubIsLargeFontSize {
                                    RouteItemViewAODA(item: self.$routeViewer.pubRouteItems[index], action: {
                                        proxy.scrollTo(index)
                                    }).id(index)
                                }else {
                                    RouteItemView(item: self.$routeViewer.pubRouteItems[index], action: {
                                        proxy.scrollTo(index)
                                    }).id(index)
                                }
							}
							Spacer().frame(height:30)
						}
						.onReceive(autoCompleteManager.didChange){ id in
							if autoCompleteManager.autoCompleteMode == .route {
								routeViewer.findRouteIndex(id) { index in
									if let index = index {
										if index >= 0 {
											routeViewer.pubHideSearchBar = true
											proxy.scrollTo(index)
											withAnimation {
												self.isMenuShown = false
											}
										}
									}
								}
							}
						}
					}
				}
    }
    
    /// Map settings view.
    /// - Parameters:
    ///   - some: Parameter description
    private var mapSettingsView: some View {
        VStack{
			HStack {
				Spacer()
				mapLayerView()
                    .addAccessibility(text: AvailableAccessibilityItem.mapLayerButton.rawValue.localized())
						.accessibility(hidden:  mapManager.pubIsInTripPlan)
			}
        }
    }
    
    /// Agency filter view.
    /// - Parameters:
    ///   - some: Parameter description
    private var agencyFilterView: some View {
        ZStack{
            VStack{
                Button(action: {
                    routeViewer.pubIsPresentRouteFilter.toggle()
                }) {
                    Image("ic_agency_filter")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(routeViewer.pubIsPresentRouteFilter ? Color.white : Color.gray)
                        .frame(width: 25, height: 25, alignment: .center)
                }
                
            }
            .frame(width: 48, height: 48)
			.background(routeViewer.pubIsPresentRouteFilter ? Color.main : Color.white)
            .clipShape(Circle())
            .padding(.leading, 20)
            .shadow(radius: 5)
			
			if RouteFilterPickerListViewModel.shared.pubIsAgencyValueChanged || RouteFilterPickerListViewModel.shared.pubIsModeValueChanged {
                Circle().fill(Color.green).frame(width: 8, height: 8, alignment: .center)
                    .offset(x: 30, y: -18)
            }
        }
    }
    
    /// Map layer options.
    /// - Parameters:
    ///   - some: Parameter description
    private var mapLayerOptions: some View {
        MapSettingsView()
    }
}
