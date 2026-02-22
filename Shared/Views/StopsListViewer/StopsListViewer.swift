//
//  StopsListViewer.swift
//

import SwiftUI
import MapKit

struct StopsListViewer: View {
	@ObservedObject var stopViewer = StopViewerViewModel.shared
	@ObservedObject var autoCompleteManager = AutoCompleteManager.shared
    @ObservedObject var mapManager = MapManager.shared
    @ObservedObject var loginFlowManager = LoginFlowManager.shared
	@ObservedObject var tabBarMenuManager = TabBarMenuManager.shared
    @State private var isMapSettings = false
    @State private var isViewNextArrivals = true
    @State private var isMenuShown = false
	@State private var stopKeyword = ""
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topTrailing) {
				ZStack {
					if !stopViewer.pubIsShowingStopViewer && tabBarMenuManager.currentItemTab == .stops{
						GeometryReader { geo in
							mapManager.map().frame(height: (geometry.size.height - geometry.size.height * 0.2), alignment: .center).edgesIgnoringSafeArea(.all).accessibility(hidden:  true)
                                .onAppear(){
								mapManager.centerRoute()
                                    if let stop = stopViewer.stop{
                                        let lat = stop.lat
                                        let lon = stop.lon
                                        let coordinates = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                                        mapManager.removeStopMarker()
                                        mapManager.addStopMarker(coordinates: coordinates)
                                        mapManager.centerCooridnateInDeepLevel(location: coordinates)
                                        mapManager.udateCompassPosition(newPosition: CGPoint(x: 15, y: (geometry.size.height * 0.2) + 15))
                                    }
							}
						}.edgesIgnoringSafeArea(.all)
					}
				}
				
				VStack {
					Spacer().frame(height:ScreenSize.safeTop())
                    if mapManager.pubHideStopSearchBar {
                        CollapsedSearchBarView(hideAddressBar: mapManager.pubHideStopSearchBar) {
                            autoCompleteManager.pubFilterKeywordForStop = ""
                            autoCompleteManager.pubFilteredItems.removeAll()
                            mapManager.removeStopMarker()
                            mapManager.centerRoute()
                            mapManager.pubHideStopSearchBar = false
                        } collapseAction: {
                            withAnimation(.easeIn(duration: 0.1)) {
                                mapManager.pubHideStopSearchBar.toggle()
                            }
                        }.padding(.horizontal, 20)
                    }
                    else{
                        ZStack{
                            LocationTextField(placeholder: "Search for a transit stop...", lineColor: Color.black, imageName: "ic_stops", colorImageWithMask:Color.black,
                                treatAsButton: true,
                                              leadingPadding: 0, text: self.$autoCompleteManager.pubFilterKeywordForStop)
                            
                            .frame(height: 55)
                                .background(Color.white)
                                .clipShape(RoundedCorner(radius: 10, corners: .allCorners))
                                .shadow(radius: 5)
                                .onTapGesture {
                                    AutoCompleteManager.shared.placeholder = "Search for a transit stop..."
                                    AutoCompleteManager.shared.textImageName = "ic_leftarrow"
                                    AutoCompleteManager.shared.autoCompleteMode = .stopList
                                    RouteFilterPickerListViewModel.shared.resetFilter()
                                    AutoCompleteManager.shared.pubOpenPage = true
                                    mapManager.removeStopMarker()
                                    let keywords = autoCompleteManager.pubFilterKeywordForStop
                                    mapManager.pubHideStopSearchBar = true
                                    if keywords.count > 0 {
                                        self.autoCompleteManager.loadSections(keywords: keywords)
                                    }
                                }
                            if AutoCompleteManager.shared.pubFilterKeywordForStop != ""{
                                HStack{
                                    Spacer()
                                    collapseButton.padding(.trailing, 10)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                    mapSettingsView
				}
				.background(Color.clear)
				.edgesIgnoringSafeArea(.bottom)
                
                if mapManager.isMapSettings {
                    VStack{
                        Spacer()
                        BottomSlideBarView(minHeight: geometry.size.height - 250, maxHeight: geometry.size.height - 250, enableDrag: false, isFullScreen: false, currentOffsetY: 0, enableCloseIndicator: true) {
                            mapLayerOptions
                        }.opacity(self.mapManager.isMapSettings ? 1.0 : 0)
                    }
                }else{
                    BottomSlideBarView(minHeight: geometry.size.height * 0.2, maxHeight: geometry.size.height * 0.76, backgroundColor: .white, enableDrag: true, isFullScreen: false, currentOffsetY: 0, enableCloseIndicator: false) {
                        StopsListView()
                    }
                }
            }
        }
        .onAppear(perform: {
            BottomSlideBarViewModel.shared.pubIsDraggable = true
        })
        .onDisappear(){
            mapManager.mapSize = .full
            mapManager.removeStopMarker()
        }
    }
    
    /// Map settings view.
    /// - Parameters:
    ///   - some: Parameter description
    private var mapSettingsView: some View {
        VStack{
            ZStack(alignment: .topLeading) {
                HStack {
                    Spacer()
                        mapLayerView()
                        .addAccessibility(text: AvailableAccessibilityItem.mapLayerButton.rawValue.localized())
                }
            }
        }
    }
    
    /// Map layer options.
    /// - Parameters:
    ///   - some: Parameter description
    private var mapLayerOptions: some View {
        MapSettingsView()
    }
    
    /// Collapse button.
    /// - Parameters:
    ///   - some: Parameter description
    private var collapseButton: some View{
        Button {
            withAnimation(.easeIn(duration: 0.1)) {
                mapManager.pubHideStopSearchBar.toggle()
            }
        } label: {
            Image(mapManager.pubHideStopSearchBar ? "btn_expand" : "btn_collapse")
                .renderingMode(.template)
                .resizable()
                .foregroundColor(.black)
                
        }.background(Color.clear)
            .frame(width: 48, height: 48, alignment: .center)
            .addAccessibility(text: (mapManager.pubHideAddressBar ? AvailableAccessibilityItem.expandButton.rawValue.localized() : AvailableAccessibilityItem.collapseButton.rawValue.localized()))
    }
}

struct StopsListViewer_Previews: PreviewProvider {
    /// Previews.
    /// - Parameters:
    ///   - some: Parameter description
    static var previews: some View {
        StopsListViewer()
    }
}
