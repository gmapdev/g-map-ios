//
//  TripViewerView.swift
//

import SwiftUI

struct TripViewerView: View {
    
    @ObservedObject var viewModel = TripViewerViewModel.shared
    @ObservedObject var mapManager = MapManager.shared
    @ObservedObject var loginFlowManager = LoginFlowManager.shared
    @ObservedObject var stopViewerModel = StopViewerViewModel.shared
    @ObservedObject var accessibilityManager = AccessibilityManager.shared
    @State var isCovered = false
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        GeometryReader { geometry in
            ZStack{
                    VStack{
                        Spacer().frame(height:ScreenSize.safeTop())
                        HStack{
                            backButton
                            Spacer()
                        }
                        Spacer()
                    }
                .zIndex(8)
                GeometryReader { geo in
                    if !stopViewerModel.pubIsShowingStopViewer {
                        mapManager.map()
                            .frame(height: geo.size.height/2, alignment: .center)
                            .edgesIgnoringSafeArea(.all)
                            .accessibility(hidden:  true)
                            .onAppear(perform: {
                                mapManager.centerRoute()
                                mapManager.udateCompassPosition(newPosition: CGPoint(x: 15, y: 25))
                            })
                    }
                }
                .offset(y: ScreenSize.safeTop())
                .zIndex(7)

                VStack{
                    HStack{ Spacer() }
                    Spacer()
                    ZStack{
                            VStack(spacing: 0){
                                if accessibilityManager.pubIsLargeFontSize {
                                    ScrollView {
                                        topInfoViewAODA
                                        accessbilityIconViewAODA()
                                            .padding(.bottom, 10)
                                        
                                        VStack(spacing: 0) {
                                            ForEach(Array(viewModel.tripInfoItems.map({ TripInfoItem(stop: $0.stop, stopTime: $0.stopTime)}).enumerated()), id: \.offset){ index, tripInfo in
                                                self.infoListView(info: tripInfo, itineraryStop: viewModel.itineraryStop,
                                                                  itinerary: viewModel.itinerary,
                                                                  stop:tripInfo.stop,
                                                                  index: index, count: viewModel.tripInfoItems.count - 1)
                                            }
                                        }
                                        Spacer().frame(height: ScreenSize.safeBottom())
                                    }
                                } else {
                                    topInfoView
                                    accessbilityIconView().padding(.vertical, 10)
                                    ScrollView(showsIndicators:false) {
                                        VStack(spacing: 0) {
                                            ForEach(Array(viewModel.tripInfoItems.map({ TripInfoItem(stop: $0.stop, stopTime: $0.stopTime)}).enumerated()), id: \.offset){ index, tripInfo in
                                                self.infoListView(info: tripInfo, itineraryStop: viewModel.itineraryStop,
                                                    itinerary: viewModel.itinerary,
                                                    stop:tripInfo.stop,
                                                                  index: index, count: viewModel.tripInfoItems.count - 1)
                                            }
                                        }
                                    }
                                }
                                
                            }
                        .padding(.top)
                        .padding(.horizontal, 16)
                        .zIndex(1)
                        
                        VStack{
                            HStack{ Spacer() }
                            Spacer()
                        }
                        .background(Color.white)
                        .clipShape(RoundedCorner(radius: 10, corners: [.topLeft, .topRight]))
                        .zIndex(0)
                    }
                    .frame(height: UIScreen.main.bounds.size.height*0.5 + ScreenSize.safeTop() + ScreenSize.safeBottom())
                }
                .zIndex(8)
            }
            .onAppear(perform: {
                viewModel.prepareTripViewerData()
                if let route = PlanTripAdapter.shared.convertToRoute(leg: viewModel.itineraryStop){
                    RouteManager.shared.presentBusRoute(route: route)
                }
            })
        }
    }
    
    /// Back button.
    /// - Parameters:
    ///   - some: Parameter description
    private var backButton: some View {
        VStack{
            Button(action: {
                backAction()
            }) {
                Image("ic_leftarrow")
                    .renderingMode(.template)
                    .resizable()
                    .padding(5)
                    .foregroundColor(.black)
            }
            .frame(width: 25, height: 30)
            .addAccessibility(text: AvailableAccessibilityItem.backButton.rawValue.localized())
            .padding(.top, 20)
            .accessibilityAction {
                backAction()
            }
        }
        .offset(y: -10)
        .frame(width: 48, height: 48, alignment: .center)
        .background(Color.white)
        .clipShape(Circle())
        .shadow(radius: 5)
        .padding(.leading)
    }
    
    /// Back action
    /// Back action.
    func backAction(){
        mapManager.forceCleanMapReDrawRoute()
        TripViewerViewModel.shared.pubIsShowingTripViewer = false
        let viewArea = ViewArea(topRight: CGPoint(x:UIScreen.main.bounds.width,y:0), bottomLeft: CGPoint(x:0, y:Helper.shared.getDeafultViewHeight(heightPosition: .middle)))
        let edgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 20)
        mapManager.setCenterArea(viewArea: viewArea, mapViewHeight: Helper.shared.getDefaultMapViewHeight(), mapViewWidth: UIScreen.main.bounds.width, edgeInset: edgeInsets)
    }
    
    /// Top info view.
    /// - Parameters:
    ///   - some: Parameter description
    var topInfoView: some View {
        VStack(alignment: .leading) {
            HStack {
                if TripPlanningManager.shared.getRouteShortName(leg: viewModel.itineraryStop) != "" {
                    HStack{
                        TextLabel(TripPlanningManager.shared.getRouteShortName(leg: viewModel.itineraryStop), .bold, .subheadline)
                            .foregroundColor(.black)
                            .padding(.vertical, 5)
                            .padding(.horizontal, 10)
                    }
                    /// Hex: "# c9 c2 d e")
                    /// Initializes a new instance.
                    /// - Parameters:

                    ///   - Color.init(hex: "#C9C2DE"
                    .background(Color.init(hex: "#C9C2DE"))
                    .cornerRadius(5)
                }
                TextLabel(TripPlanningManager.shared.getRouteLongName(leg: viewModel.itineraryStop), .bold, .body)
                    .foregroundColor(.black)
                Spacer()
                
            }
            
        }
    }
    
    /// Top info view a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    var topInfoViewAODA: some View {
        HStack{
            VStack(alignment: .leading, spacing: 5){
                HStack{
                    TextLabel(TripPlanningManager.shared.getRouteShortName(leg: viewModel.itineraryStop), .bold, .subheadline)
                        .foregroundColor(.black)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                /// Hex: "# c9 c2 d e")
                /// Initializes a new instance.
                /// - Parameters:

                ///   - Color.init(hex: "#C9C2DE"
                }.background(Color.init(hex: "#C9C2DE"))
                    .cornerRadius(5)
                TextLabel(TripPlanningManager.shared.getRouteLongName(leg: viewModel.itineraryStop), .bold, .body)
                    .foregroundColor(.black)
                    .fixedSize(horizontal: false, vertical: true)
                
            }
            Spacer()
        }
    }
    
    /// Accessbility icon view
    /// - Returns: some View
    /// Accessbility icon view.
    func accessbilityIconView() -> some View {
        HStack{
            if let tripDetails = self.viewModel.tripDetails{
                if tripDetails.bikesAllowed == 1 {
                    bikeAllowedIcon
                }
                
                if tripDetails.wheelchairAccessible == 1 {
                    wheelchairAccessibleIcon
                }
            }
            Spacer()
        }
    }
    
    /// Accessbility icon view a o d a
    /// - Returns: some View
    /// Accessbility icon view aoda.
    func accessbilityIconViewAODA() -> some View {
        VStack{
            if let tripDetails = self.viewModel.tripDetails{
                    HStack {
                        bikeAllowedIcon
                        Spacer()
                    }
                    HStack {
                        wheelchairAccessibleIcon
                        Spacer()
                    }
            }
        }
    }
    
    /// Bike allowed icon.
    /// - Parameters:
    ///   - some: Parameter description
    private var bikeAllowedIcon: some View{
        HStack{
            Image("ic_bike")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.white)
                .frame(width: accessibilityManager.pubIsLargeFontSize ? accessibilityManager.getFontSize() : 20, height: accessibilityManager.pubIsLargeFontSize ? accessibilityManager.getFontSize() : 20, alignment: .center)
                
            TextLabel("Allowed".localized(), .bold, .footnote)
        }
        .foregroundColor(.white)
        .padding(.all, 5)
        .background(Color.green)
        .cornerRadius(5)
    }
    
    /// Wheelchair accessible icon.
    /// - Parameters:
    ///   - some: Parameter description
    private var wheelchairAccessibleIcon: some View{
        HStack{
            Image("ic_wheelchair_white")
                .resizable()
                .renderingMode(.template)
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.white)
                .frame(width: accessibilityManager.pubIsLargeFontSize ? accessibilityManager.getFontSize() : 20, height: accessibilityManager.pubIsLargeFontSize ? accessibilityManager.getFontSize() : 20, alignment: .center)
                
            TextLabel("Allowed".localized(), .bold, .footnote)
        }
        .foregroundColor(.white)
        .padding(.all, 5)
        .background(Color(hex: "#3b79b7"))
        .cornerRadius(5)
    }
    
    /// Info list view.
    /// - Parameters:
    ///   - info: Parameter description
    ///   - itineraryStop: Parameter description
    ///   - itinerary: Parameter description
    ///   - stop: Parameter description
    ///   - index: Parameter description
    ///   - count: Parameter description
    /// - Returns: some View
    private func infoListView(info: TripInfoItem, itineraryStop: OTPLeg?, itinerary: OTPItinerary?, stop: Stop, index: Int, count: Int) -> some View {
        return HStack{
            if !accessibilityManager.pubIsLargeFontSize {
                TextLabel(info.stopTime?.departureDate.time() ?? "")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .frame(width: 50, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.center)
            }
            ZStack{
                if index != 0 && index != count {
                    RoundedRectangle(cornerRadius: 0)
                        .frame(width: 5, alignment: .center)
                        .foregroundColor(Color(hex: "#13C1C1"))
                        .alignmentGuide(.leading) { dimensions in
                            dimensions[HorizontalAlignment.trailing]
                        }
                        .zIndex(1)
                }
                
                if getCoveredStops(stopName: info.stop.name){
                    Circle()
                        .fill(Color(hex: "#13C1C1"))
                        .frame(width: 25, height: 25, alignment: .center)
                        .background(Circle().foregroundColor(Color.white))
                        .zIndex(9)
                }else{
                    Circle().strokeBorder(Color(hex: "#13C1C1"), lineWidth: 5)
                        .frame(width: 25, height: 25, alignment: .center)
                        .background(Circle().foregroundColor(Color.white))
                        .zIndex(9)
                }
                if index == 0{
                    ZStack{
                        VStack(spacing: 0){
                            Image("ic_origin").resizable().frame(width: 25, height: 25, alignment: .center).background(Color.white).zIndex(9)
                            RoundedRectangle(cornerRadius: 0)
                                .frame(width: 5, alignment: .center).frame(minHeight: 80)
                                .foregroundColor(Color(hex: "#13C1C1"))
                                .zIndex(1)
                        }
                        
                    }.cornerRadius(10)
                }
                
                if index == count{
                    ZStack{
                        VStack(spacing: 0){
                            RoundedRectangle(cornerRadius: 0)
                                .frame(width: 5, alignment: .center).frame(minHeight: 80)
                                .foregroundColor(Color(hex: "#13C1C1")).zIndex(1)
                            Image("ic_location").resizable().frame(width: 25, height: 25, alignment: .center).background(Color.white).zIndex(9)
                        }
                    }.cornerRadius(10)
                }
                
            }
            
            Spacer()
            if accessibilityManager.pubIsLargeFontSize {
                infoViewAODA(info: info, itineraryStop: itineraryStop, itinerary: itinerary, stop: stop, index: index, count: count)
            } else {
                infoView(info: info, itineraryStop: itineraryStop, itinerary: itinerary, stop: stop, index: index, count: count)
            }
            
        }
        .padding(.trailing, 5)
        .frame(minHeight: index == count ? 55+ScreenSize.safeBottom() : 50, alignment: .center)
    }
    
    /// Info view.
    /// - Parameters:
    ///   - info: Parameter description
    ///   - itineraryStop: Parameter description
    ///   - itinerary: Parameter description
    ///   - stop: Parameter description
    ///   - index: Parameter description
    ///   - count: Parameter description
    /// - Returns: some View
    func infoView(info: TripInfoItem, itineraryStop: OTPLeg?, itinerary: OTPItinerary?, stop: Stop, index: Int, count: Int) -> some View {
        HStack {
            TextLabel(info.stop.name.trimmingCharacters(in: .whitespaces), index == 0 || index == count ? .bold : .regular, .subheadline)
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(.gray)
            
            Spacer()
            
            Button(action: {
                //MARK: Fix it later
                showStopViewer(itineraryStop: itineraryStop, itinerary: itinerary, stop: stop)
            }) {
                TextLabel("View".localized())
                    .font(.subheadline)
                    .foregroundColor(.black)
                    .frame(width: 65, height: 40)
            }.background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)
        }
    }
    
    /// Info view a o d a.
    /// - Parameters:
    ///   - info: Parameter description
    ///   - itineraryStop: Parameter description
    ///   - itinerary: Parameter description
    ///   - stop: Parameter description
    ///   - index: Parameter description
    ///   - count: Parameter description
    /// - Returns: some View
    func infoViewAODA(info: TripInfoItem, itineraryStop: OTPLeg?, itinerary: OTPItinerary?, stop: Stop, index: Int, count: Int) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 5){
                TextLabel(info.stopTime?.departureDate.time() ?? "")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
                
                TextLabel(info.stop.name.trimmingCharacters(in: .whitespaces),index == 0 || index == count ? .bold : .regular, .subheadline)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundColor(.gray)
                
                Button(action: {
                    showStopViewer(itineraryStop: itineraryStop, itinerary: itinerary, stop: stop)
                }) {
                    TextLabel("View".localized())
                        .font(.subheadline)
                        .foregroundColor(.black)
                        .padding(10)
                }.background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    .padding(.top, 5)
                HorizontalLine(color: Color.gray)
                    .padding(.top, 5)
                    .padding(.bottom, 10)
            }
            Spacer()
        }
        .padding(.top, 10)
    }
    
    /// Show stop viewer.
    /// - Parameters:
    ///   - itineraryStop: Parameter description
    ///   - itinerary: Parameter description
    ///   - stop: Parameter description
    func showStopViewer(itineraryStop: OTPLeg?, itinerary: OTPItinerary?, stop: Stop) {
        stopViewerModel.itinerary = itinerary
        stopViewerModel.itineraryStop = itineraryStop
        stopViewerModel.stop = stop
        stopViewerModel.getGraphQLStopTimes()
        stopViewerModel.getGraphQLStopSchedules()
        stopViewerModel.pubStopViewerOrigin = .tripDetail
        stopViewerModel.addStopMarker()
        stopViewerModel.pubIsShowingStopViewer = true
        viewModel.pubIsShowingTripViewer = false
    }
    
    /// Get covered stops.
    /// - Parameters:
    ///   - stopName: Parameter description
    /// - Returns: Bool
    func getCoveredStops(stopName: String) -> Bool{
        if let stopsArray = viewModel.itineraryStop?.intermediateStops{
            for stop in stopsArray{
                if stop.name == stopName {
                    return true
                }
            }
        }
        return false
    }
}

