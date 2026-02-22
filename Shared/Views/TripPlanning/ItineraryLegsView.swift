//
//  ItineraryLegsView.swift
//

import SwiftUI
import Mapbox

enum StepConnectorShape: String {
    case dashedLine = "dashedLine"
    case dotLine = "dotLine"
    case solidLine = "solidLine"
}

struct ItineraryLegsView: View {
    let itinerary: OTPItinerary
    var stopViewerAction: ((OTPItinerary, OTPLeg) -> Void)? = nil
    var tripViewerAction: ((OTPItinerary, OTPLeg) -> Void)? = nil
    var tripManageViewerAction: ((OTPItinerary, OTPLeg) -> Void)? = nil
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        let legs = itinerary.legs?.map({GraphQLTripLeg(leg: $0)}) ?? []
        return VStack(alignment: .leading, spacing:0) {
            ForEach(Array(legs.enumerated()), id: \.offset) { index, leg in
                LegDetailView(leg: leg, isFirst: index == 0, isLast: index == legs.count - 1 && legs.count > 0, itinerary: itinerary, stopViewerAction: { itinerary,leg in
                    stopViewerAction?(itinerary, leg)
                }, tripViewerAction: {itinerary,leg in
                    tripViewerAction?(itinerary, leg)
                }, tripManageViewerAction: {itinerary, leg in
                    tripManageViewerAction?(itinerary, leg)
                })
				.background(PreviewTripManager.shared.currentTripSteps.count > PreviewTripManager.shared.currentStepIndex ? ((PreviewTripManager.shared.currentTripSteps[PreviewTripManager.shared.currentStepIndex].leg.leg?.previewStepId ?? "") == (leg.leg?.previewStepId ?? "") ? Color.main.opacity(0.4) : Color.clear) : Color.clear)
				.id(leg.leg?.previewStepId ?? UUID().uuidString)
            }
        }
        .cornerRadius(5)
    }
    
}

struct LegDetailView : View {
    var leg: GraphQLTripLeg
    var isFirst = false
    var isLast = false
    @State var isExpandedDirection = false
    let itinerary: OTPItinerary
    var stopViewerAction: ((OTPItinerary, OTPLeg) -> Void)? = nil
    var tripViewerAction: ((OTPItinerary, OTPLeg) -> Void)? = nil
    var tripManageViewerAction: ((OTPItinerary, OTPLeg) -> Void)? = nil
    @ObservedObject var envManager = EnvironmentManager.shared
    @ObservedObject var bottomSlideBarModel = BottomSlideBarViewModel.shared
    @ObservedObject var routeViewer = RouteViewerModel.shared
    @ObservedObject var tripPlanManager = TripPlanningManager.shared
    @ObservedObject var liveRouteManger = LiveRouteManager.shared
    var modeManager = ModeManager.shared
    
    /// Theme text color.
    /// - Parameters:
    ///   - Color: Parameter description
    var themeTextColor: Color {
        get{
            return Color.blue
        }
    }
    
    /// Itinerary step.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: some View
    func itineraryStep(_ isLast: Bool) -> some View {
        let imageSize = AccessibilityManager.shared.pubIsLargeFontSize ? AccessibilityManager.shared.getFontSize() : 30
        let alerts = tripPlanManager.getAlertsArray(leg: leg.leg)
        return VStack(spacing:0){
            if AccessibilityManager.shared.pubIsLargeFontSize {
                stepTopViewAODA
            } else {
                stepTopView
            }
            
            ZStack{
                GeometryReader { reader in
                    HStack{
                        Spacer().frame(width:10)
                        if let optionalLeg = leg.leg, let searchMode = optionalLeg.searchMode, searchMode.mode == Mode.walk.rawValue {
                            circleslineView(height: reader.frame(in: .local).height,leg: leg)
                                .frame(width: 10)
                        }
                        else if let optionalLeg = leg.leg, let searchMode = optionalLeg.searchMode, searchMode.mode == Mode.bicycle.rawValue {
                            dashLine(height: reader.frame(in: .local).height, leg: leg)
                                .frame(width: 10)
                        }
                        else {
                            solidLine(height: reader.frame(in: .local).height, leg: leg)
                                .frame(width: 10)
                        }
                        Spacer()
                    }
                }
                
                HStack {
                    Spacer().frame(width:40)
                    VStack(alignment: .leading) {
                            if tripPlanManager.stopDisplayIdentifier(leg: leg.leg) != "" {
                                if AccessibilityManager.shared.pubIsLargeFontSize {
                                    stopIDViewAODA(leg: leg).padding(.top, 5)
                                } else {
                                    stopIDView(leg: leg).padding(.top, 5)
                                        .frame(height: 30)
                                }
                            }else {
                                Spacer().frame(height: 5)
                            }
                        HStack {
                            Button(action: {
								PreviewTripManager.shared.showSegment(leg: leg)
								if let previousStepId = leg.leg?.previewStepId {
									PreviewTripManager.shared.adjustFirstSelectedSection(previewStepId: previousStepId)
								}
                            }, label: {
                            // MARK: FIX IT LATER
                                interprateLegMode(stop:leg.leg)
                            })
                        }
                        
                        if let optionalLeg = leg.leg, optionalLeg.transitLeg == true {
                            serviceView(leg: leg, imageSize: imageSize)
                        }
                        
                        if alerts.count > 0 {
                            legAlertView(alertsCount: alerts.count, leg: leg.leg, imageSize: imageSize)
                        }
                        if let otpLeg = leg.leg, let searchMode = otpLeg.searchMode, searchMode.mode != "FERRY" {
                            legStepsView(leg: leg, isFirst: isFirst, isLast: isLast, imageSize: imageSize)
                        }
                    }
                }
            }
            .padding(.leading, 5)
            
            if isLast {
                if AccessibilityManager.shared.pubIsLargeFontSize {
                    lastLegViewAODA
                } else {
                    lastLegView
                }
            }
        }
    }
    
    /// Last leg view.
    /// - Parameters:
    ///   - some: Parameter description
    var lastLegView: some View {
        HStack{
            HStack{
                Image("map_to_icon")
                    .resizable()
                    .frame(width: 20, height: 20)
                    .background(Color.white)
            }
            .frame(width: 30, height: 30)
            .background(Color.white)
            .clipShape(Circle())
            .shadow(radius: 3)
            .addAccessibility(text: "Destination Icon".localized())
            LegTitleView(time: tripPlanManager.milliSecondsTimeToLocalZone(time: String(leg.leg?.endTime ?? 0),delay: Double(leg.leg?.departureDelay ?? 0)),
                         icon: "map_to_icon",
                         name: liveRouteManger.pubIsRouteActivated ? liveRouteManger.getToNameOfTrip() : SearchManager.shared.to?.properties.label ?? "",
                         delay: Double(leg.leg?.departureDelay ?? 0),
                         isRealtime: leg.leg?.realTime ?? false,
                         interLineWithPreviousLeg: false)
            Spacer()
        }
        .padding(.top, 15)
        .padding([.leading, .bottom], 5)
    }
    
    /// Last leg view a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    var lastLegViewAODA: some View {
        VStack{
            HStack {
                HStack{
                    Image("map_to_icon")
                        .resizable()
                        .frame(width: AccessibilityManager.shared.getFontSize() - 10, height: AccessibilityManager.shared.getFontSize() - 10)
                        .background(Color.white)
                }
                .frame(width: AccessibilityManager.shared.getFontSize(), height: AccessibilityManager.shared.getFontSize())
                .background(Color.white)
                .clipShape(Circle())
                .shadow(radius: 3)
                .addAccessibility(text: "Destination Icon".localized())
                Spacer()
            }
            LegTitleView(time: tripPlanManager.milliSecondsTimeToLocalZone(time: String(leg.leg?.endTime ?? 0), delay: Double(leg.leg?.departureDelay ?? 0)),
                         icon: "map_to_icon",
                         name: liveRouteManger.pubIsRouteActivated ? liveRouteManger.getToNameOfTrip() : SearchManager.shared.to?.properties.label ?? "",
                         delay: Double(leg.leg?.departureDelay ?? 0),
                         isRealtime: leg.leg?.realTime ?? false,
                         interLineWithPreviousLeg: false)
            Spacer()
        }
        .padding(.top, 15)
        .padding([.leading, .bottom], 5)
    }
    
    /// Step top view.
    /// - Parameters:
    ///   - some: Parameter description
    var stepTopView: some View {
        HStack{
            HStack{
                Image(modeManager.getImageIconforSearchRoute(leg:leg.leg))
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(Color.black)
                    .frame(width: 20, height: 20)
                    .background(Color.white)
            }
            .frame(width:30, height:30)
            .background(Color.white)
            .clipShape(Circle())
            .shadow(radius: 3)
            .padding(.top, isFirst ? 5 : 0)
            .addAccessibility(text: "%1 icon".localized(leg.leg?.mode ?? ""))
            Button(action: {
				PreviewTripManager.shared.showSegment(leg: leg)
				if let previousStepId = leg.leg?.previewStepId {
					PreviewTripManager.shared.adjustFirstSelectedSection(previewStepId: previousStepId)
				}
            }, label: {
				LegTitleView(time: tripPlanManager.milliSecondsTimeToLocalZone(time: String(leg.leg?.startTime ?? 0), delay: Double(leg.leg?.departureDelay ?? 0)),
								 icon: legImage(leg: leg, isFirst: isFirst),
								 name: PreviewTripManager.shared.legName(leg: leg, isFirst: isFirst),
								 delay: Double(leg.leg?.departureDelay ?? 0),
								 isRealtime: leg.leg?.realTime ?? false,
								 interLineWithPreviousLeg: leg.leg?.interlineWithPreviousLeg ?? false)
            })
            .accessibilityRemoveTraits(.isButton)
            
            Spacer()
        }
        .padding(.leading, 5)
    }
    
    /// Step top view a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    var stepTopViewAODA: some View {
        VStack(spacing: 5){
            HStack {
                HStack{
                    Image(modeManager.getImageIconforSearchRoute(leg:leg.leg))
                        .renderingMode(.template)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(Color.black)
                        .frame(width: AccessibilityManager.shared.getFontSize() - 10, height: AccessibilityManager.shared.getFontSize() - 10)
                        .background(Color.white)
                }
                .frame(width: AccessibilityManager.shared.getFontSize(), height: AccessibilityManager.shared.getFontSize())
                .background(Color.white)
                .clipShape(Circle())
                .shadow(radius: 3)
                .padding(.top, isFirst ? 5 : 0)
                .addAccessibility(text: "%1 icon".localized(leg.leg?.mode ?? ""))
                Spacer()
            }
            .padding(.top, 10)
            Button(action: {
				PreviewTripManager.shared.showSegment(leg: leg)
				if let previousStepId = leg.leg?.previewStepId {
					PreviewTripManager.shared.adjustFirstSelectedSection(previewStepId: previousStepId)
				}
            }, label: {
                LegTitleView(time: tripPlanManager.milliSecondsTimeToLocalZone(time: String(leg.leg?.startTime ?? 0), delay: Double(leg.leg?.departureDelay ?? 0)),
                             icon: legImage(leg: leg, isFirst: isFirst),
							 name: PreviewTripManager.shared.legName(leg: leg, isFirst: isFirst), delay: Double(leg.leg?.departureDelay ?? 0), isRealtime: leg.leg?.realTime ?? false, interLineWithPreviousLeg: leg.leg?.interlineWithPreviousLeg ?? false)
            })
            .accessibilityRemoveTraits(.isButton)
        }
        .padding(.leading, 10)
    }
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        itineraryStep(isLast)
    }
    
    /// Leg image.
    /// - Parameters:
    ///   - leg: Parameter description
    ///   - isFirst: Parameter description
    /// - Returns: String
    private func legImage(leg: GraphQLTripLeg, isFirst: Bool = false) -> String {
        var image = "checkmark_circle_disabled_icon"
        if isFirst {
            image = "map_from_icon"
        }
        return image
    }
    
    /// Circlesline view.
    /// - Parameters:
    ///   - height: Parameter description
    ///   - leg: Parameter description
    /// - Returns: some View
    private func circleslineView(height: CGFloat, leg: GraphQLTripLeg) -> some View {
        return stepConnectorShape(type: .dotLine, height: height, leg: leg)
    }
    
    /// Solid line.
    /// - Parameters:
    ///   - height: Parameter description
    ///   - leg: Parameter description
    /// - Returns: some View
    private func solidLine(height: CGFloat, leg: GraphQLTripLeg) -> some View {
        return stepConnectorShape(type: .solidLine, height: height, leg: leg)
    }
    
    /// Dash line.
    /// - Parameters:
    ///   - height: Parameter description
    ///   - leg: Parameter description
    /// - Returns: some View
    private func dashLine(height: CGFloat, leg: GraphQLTripLeg) -> some View {
        return stepConnectorShape(type: .dashedLine, height: height, leg: leg)
    }
    
    /// Step connector shape.
    /// - Parameters:
    ///   - type: Parameter description
    ///   - height: Parameter description
    ///   - leg: Parameter description
    /// - Returns: some View
    private func stepConnectorShape(type: StepConnectorShape = .solidLine, height: CGFloat, leg: GraphQLTripLeg) -> some View {
        let topBottomOffset: CGFloat = 4
        let barHeight:CGFloat = 8
        var count = Int( (height - topBottomOffset)  / CGFloat(barHeight))
        if count < 0 { count = 0}
        var w:CGFloat = barHeight * 0.55
        var h:CGFloat = barHeight
        var corner: CGFloat = 0
        if type == .dashedLine { w = barHeight*0.55; h = barHeight*0.75 }
        else if type == .dotLine { w = barHeight*0.65; h = barHeight*0.65; corner = barHeight*0.325}
        return VStack(spacing: 0){
            if !isFirst {
                Spacer().frame(height:topBottomOffset/2)
            }
            
            ForEach(0..<count, id: \.self) { index in
                HStack{
                    Spacer()
                }
                .frame(width:w, height:h)
                .background(Color(hex: tripPlanManager.getRouteColor(leg: leg.leg)))
                .cornerRadius(corner)
                Spacer().frame(height: barHeight - h)
            }
            
            if count != 0 {
                HStack{
                    Spacer()
                    
                }
                .frame(width:w, height:h)
                .background(Color(hex: tripPlanManager.getRouteColor(leg: leg.leg)))
                .cornerRadius(corner)
            }
            
            Spacer().frame(height: topBottomOffset/2)
        }
        .frame(height:height)
    }
    
    /// Stop i d view.
    /// - Parameters:
    ///   - leg: Parameter description
    /// - Returns: some View
    private func stopIDView(leg: GraphQLTripLeg) -> some View {
        let stopId = tripPlanManager.stopDisplayIdentifier(leg: leg.leg)
        return HStack {
            TextLabel("Stop ID %1".localized(stopId))
                .font(.footnote)
                .foregroundColor(.gray_subtitle_color)
            Divider()
                .frame(width: 1)
                .background(Color.black)
            Button(action: {
                if let leg = leg.leg{
                    StopViewerViewModel.shared.itineraryStop = leg
                    stopViewerAction?(itinerary, leg)
                }
            }) {
                HStack {
                    TextLabel("Stop Viewer".localized())
                        .font(.footnote)
                        .foregroundColor(themeTextColor)
                    Spacer()
                }
            }
        }
    }
    
    /// Stop i d view a o d a.
    /// - Parameters:
    ///   - leg: Parameter description
    /// - Returns: some View
    private func stopIDViewAODA(leg: GraphQLTripLeg) -> some View {
        let stopId = tripPlanManager.stopDisplayIdentifier(leg: leg.leg)
        return VStack {
            HStack {
                TextLabel("Stop ID %1".localized(stopId))
                    .font(.footnote)
                    .foregroundColor(.gray_subtitle_color)
                Spacer()
            }
            Button(action: {
                if let leg = leg.leg{
                    StopViewerViewModel.shared.itineraryStop = leg
                    stopViewerAction?(itinerary, leg)
                }
            }) {
                HStack {
                    TextLabel("Stop Viewer".localized())
                        .font(.footnote)
                        .foregroundColor(themeTextColor)
                    Spacer()
                }
            }
        }
    }
    
    /// Service view.
    /// - Parameters:
    ///   - leg: Parameter description
    ///   - imageSize: Parameter description
    /// - Returns: some View
    private func serviceView(leg: GraphQLTripLeg, imageSize: CGFloat) -> some View {
        let text = Text("Service operated by".localized() + " ").font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.footnote.size)).foregroundColor(.gray_subtitle_color)
        let agencyName = Helper.shared.mapAgencyNameAliase(agencyName: leg.leg?.agency?.name ?? "")
        let agencyNameText = Text(agencyName).font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.footnote.size)).foregroundColor(.blue)
        return HStack(spacing: 2) {
            (text + agencyNameText)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)

            Image(uiImage: routeViewer.agencyLogos[agencyName.lowercased()]?.resizeImage(imageSize, imageSize) ?? UIImage())
                .frame(width: imageSize, height: imageSize, alignment: .center)
                .aspectRatio(contentMode: .fit)
        }.onTapGesture {
            if let url = URL(string: leg.leg?.agency?.url ?? "") {
                UIApplication.shared.open(url)
            }
        }
        .addAccessibility(text: agencyName.localized())
    }
    
    /// Interprate leg mode.
    /// - Parameters:
    ///   - stop: Parameter description
    /// - Returns: some View
    private func interprateLegMode(stop: OTPLeg?) -> some View {
        if let stop = stop {
            let routeName = tripPlanManager.getRouteName(leg: stop)
            let routeLongName = tripPlanManager.getRouteLongName(leg: stop)
            let routeShortName = tripPlanManager.getRouteShortName(leg: stop)
            let headsign = stop.headsign ?? ""
            var displayRouteName = tripPlanManager.renderRouteInfo(routeShortName: routeShortName, routeLongName: routeLongName, headsign: headsign)
            if routeName == displayRouteName {
                displayRouteName = ""
            }
            let (accessibilityType, color) = tripPlanManager.getaccessibilityConfidenceForLeg(leg: stop)
            let accessibilityIconSize = AccessibilityManager.shared.pubIsLargeFontSize ? AccessibilityManager.shared.getFontSize()*0.65 : 34
            if stop.searchMode?.mode == Mode.walk.rawValue {
                let distance = stop.distance ?? 0.0
                let distanceMiles = distance*0.000621371
                var distanceMilesText = String(format: "%.1f", distanceMiles)
                // MARK: Fix it later
                let destination = stop.to?.meaningfulName()
                var final = "Walk %1 miles to %2".localized("\(distanceMilesText)", "\(destination ?? "")")
                if distanceMiles < 0.1 {
                    let feetValue = distanceMiles*5280
                    distanceMilesText =  String(format: "%.0f", feetValue)
                    final = "Walk %1 feet to %2".localized("\(distanceMilesText)", "\(destination ?? "")")
                }
                return AnyView(
                    VStack(alignment:.leading){
                        HStack{ Spacer()}
                        if AccessibilityManager.shared.pubIsLargeFontSize {
                            VStack(alignment: .leading){
                                TextLabel(final).font(.footnote).foregroundColor(.gray_subtitle_color)
                                    .multilineTextAlignment(.leading).lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                                VStack {
                                    if accessibilityType == .accessible {
                                        HStack {
                                            Image("ic_wheelchair_black")
                                                .resizable()
                                                .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                                            Image("ic_like")
                                                .resizable()
                                                .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                                        }
                                        .foregroundStyle(Color.black)
                                        .frame(minHeight: accessibilityIconSize + 10)
                                        .padding(2)
                                        .background(color)
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                        .roundedBorderWithColor(5, 0, Color.black)
                                    } else if accessibilityType == .accessibilityUnknown {
                                        HStack {
                                            Image("ic_wheelchair_black")
                                                .resizable()
                                                .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                                            Image("ic_help_circle")
                                                .resizable()
                                                .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                                        }
                                        .foregroundStyle(Color.black)
                                        .frame(minHeight: accessibilityIconSize + 10)
                                        .padding(2)
                                        .background(color)
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                        .roundedBorderWithColor(5, 0, Color.black)
                                    } else if accessibilityType == .notAccessible {
                                        HStack {
                                            Image("ic_wheelchair_black")
                                                .resizable()
                                                .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                                            Image("ic_dislike")
                                                .resizable()
                                                .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                                        }
                                        .foregroundStyle(Color.black)
                                        .frame(minHeight: accessibilityIconSize + 10)
                                        .padding(2)
                                        .background(color)
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                        .roundedBorderWithColor(5, 0, Color.black)
                                    }
                                }
                            }
                        } else {
                            HStack {
                                VStack {
                                    if accessibilityType == .accessible {
                                        HStack {
                                            Image("ic_wheelchair_black")
                                            Image("ic_like")
                                        }
                                        .foregroundStyle(Color.black)
                                        .frame(minHeight: 34)
                                        .padding(2)
                                        .background(color)
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                        .roundedBorderWithColor(5, 0, Color.black)
                                    } else if accessibilityType == .accessibilityUnknown {
                                        HStack {
                                            Image("ic_wheelchair_black")
                                            Image("ic_help_circle")
                                        }
                                        .foregroundStyle(Color.black)
                                        .frame(minHeight: 34)
                                        .padding(2)
                                        .background(color)
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                        .roundedBorderWithColor(5, 0, Color.black)
                                    } else if accessibilityType == .notAccessible {
                                        HStack {
                                            Image("ic_wheelchair_black")
                                            Image("ic_dislike")
                                        }
                                        .foregroundStyle(Color.black)
                                        .frame(minHeight: 34)
                                        .padding(2)
                                        .background(color)
                                        .clipShape(RoundedRectangle(cornerRadius: 5))
                                        .roundedBorderWithColor(5, 0, Color.black)
                                    }
                                }
                                TextLabel(final).font(.footnote).foregroundColor(.gray_subtitle_color)
                                    .multilineTextAlignment(.leading).lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    })
            }
            else if stop.searchMode?.mode == Mode.bus.rawValue || stop.searchMode?.mode == Mode.tram.rawValue || stop.searchMode?.mode == Mode.ferry.rawValue || stop.searchMode?.mode == Mode.water_taxi.rawValue || stop.searchMode?.mode == Mode.monorail.rawValue || stop.searchMode?.mode == Mode.rail.rawValue{
                if AccessibilityManager.shared.pubIsLargeFontSize {
                    return AnyView(VStack(alignment: .leading){
                        if routeName != "" {
                            VStack(spacing: 0){
                                VStack(spacing: 0){
                                    HStack{Spacer()}
                                    Spacer()
                                }.padding(.horizontal, 5)
                                    .frame(minWidth: tripPlanManager.getRouteBannerWidth(routeName: routeName), maxWidth: tripPlanManager.getRouteBannerWidth(routeName: routeName))
                                    .frame(height: 10).background(Color(hex: tripPlanManager.getRouteColor(leg: stop))).opacity(1)
                                
                                HStack{
                                    Spacer()
                                    TextLabel(routeName).font(.subheadline).foregroundColor(Color.black)
                                        .fixedSize(horizontal: false, vertical: true)
                                    Spacer()
                                }
                                .padding(.horizontal, 5)
                                .frame(minWidth: tripPlanManager.getRouteBannerWidth(routeName: routeName), maxWidth: tripPlanManager.getRouteBannerWidth(routeName: routeName), minHeight: tripPlanManager.getRouteBannerHeight(routeName: routeName))
                                .background(Color(hex: tripPlanManager.getRouteColor(leg: stop)).opacity(0.5))
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                        }
                        VStack {
                            if accessibilityType == .accessible {
                                HStack {
                                    Image("ic_wheelchair_black")
                                        .resizable()
                                        .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                                    Image("ic_like")
                                        .resizable()
                                        .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                                }
                                .foregroundStyle(Color.black)
                                .frame(minHeight: accessibilityIconSize + 10)
                                .padding(2)
                                .background(color)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                .roundedBorderWithColor(5, 0, Color.black)
                            } else if accessibilityType == .accessibilityUnknown {
                                HStack {
                                    Image("ic_wheelchair_black")
                                        .resizable()
                                        .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                                    Image("ic_help_circle")
                                        .resizable()
                                        .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                                }
                                .foregroundStyle(Color.black)
                                .frame(minHeight: accessibilityIconSize + 10)
                                .padding(2)
                                .background(color)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                .roundedBorderWithColor(5, 0, Color.black)
                            } else if accessibilityType == .notAccessible {
                                HStack {
                                    Image("ic_wheelchair_black")
                                        .resizable()
                                        .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                                    Image("ic_dislike")
                                        .resizable()
                                        .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                                }
                                .foregroundStyle(Color.black)
                                .frame(minHeight: accessibilityIconSize + 10)
                                .padding(2)
                                .background(color)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                                .roundedBorderWithColor(5, 0, Color.black)
                            }
                        }
                        VStack(alignment:.leading){
                            HStack{Spacer()}
//                            TextLabel("\(stop.route?.longName ?? "")")
                            TextLabel(displayRouteName)
                                .font(.footnote).foregroundColor(.gray_subtitle_color)
                                .multilineTextAlignment(.leading).lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding([.leading, .bottom], 2)
                    })
                } else {
                    return AnyView(VStack(alignment: .leading) {
                        HStack{
                            if routeName != "" {
                                VStack(spacing: 0){
                                    VStack(spacing: 0){
                                        HStack{Spacer()}
                                        Spacer()
                                    }.padding(.horizontal, 5)
                                        .frame(minWidth: tripPlanManager.getRouteBannerWidth(routeName: routeName, isTripDetail: true), maxWidth: tripPlanManager.getRouteBannerWidth(routeName: routeName, isTripDetail: true))
                                        .frame(height: 10).background(Color(hex: tripPlanManager.getRouteColor(leg: stop))).opacity(1)
                                    
                                    HStack{
                                        Spacer()
                                        TextLabel(routeName).font(.subheadline).foregroundColor(Color.black)
                                            .fixedSize(horizontal: false, vertical: true)
                                        Spacer()
                                    }
                                    .padding(.horizontal, 5)
                                    .frame(minWidth: tripPlanManager.getRouteBannerWidth(routeName: routeName, isTripDetail: true), maxWidth: tripPlanManager.getRouteBannerWidth(routeName: routeName, isTripDetail: true), minHeight: tripPlanManager.getRouteBannerHeight(routeName: routeName, isTripDetail: true), maxHeight: tripPlanManager.getRouteBannerHeight(routeName: routeName, isTripDetail: true))
                                    .background(Color(hex: tripPlanManager.getRouteColor(leg: stop)).opacity(0.5))
                                }
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                            }
                            Spacer().frame(width: 5)
                            VStack {
                                if accessibilityType == .accessible {
                                    HStack {
                                        Image("ic_wheelchair_black")
                                        Image("ic_like")
                                    }
                                    .foregroundStyle(Color.black)
                                    .frame(minHeight: 34)
                                    .padding(2)
                                    .background(color)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                    .roundedBorderWithColor(5, 0, Color.black)
                                } else if accessibilityType == .accessibilityUnknown {
                                    HStack {
                                        Image("ic_wheelchair_black")
                                        Image("ic_help_circle")
                                    }
                                    .foregroundStyle(Color.black)
                                    .frame(minHeight: 34)
                                    .padding(2)
                                    .background(color)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                    .roundedBorderWithColor(5, 0, Color.black)
                                } else if accessibilityType == .notAccessible {
                                    HStack {
                                        Image("ic_wheelchair_black")
                                        Image("ic_dislike")
                                    }
                                    .foregroundStyle(Color.black)
                                    .frame(minHeight: 34)
                                    .padding(2)
                                    .background(color)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                    .roundedBorderWithColor(5, 0, Color.black)
                                }
                            }
                            TextLabel(displayRouteName).font(.footnote).foregroundColor(.gray_subtitle_color)
                                .multilineTextAlignment(.leading).lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        if stop.searchMode?.mode == "FERRY" {
                            VStack(alignment:.leading){
                                HStack{Spacer()}
                                TextLabel("\(stop.route?.longName ?? "")").font(.footnote).foregroundColor(.gray_subtitle_color)
                                    .multilineTextAlignment(.leading).lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding([.leading, .bottom], 2)
                        }
                    }.padding(.top, 2))
                }
            }
            
            else if stop.searchMode?.mode == Mode.subway.rawValue {
                return AnyView(HStack{
                    ZStack{
                        /// Hex: "#006 a a9")
                        /// Initializes a new instance.
                        /// - Parameters:
                        ///   - cornerRadius: 10
                        RoundedRectangle(cornerRadius: 10).frame(width: 40, height: 20, alignment: .center).foregroundColor(Color.init(hex: "#006AA9"))
                        VStack{
                            Spacer()
                            TextLabel(stop.route?.shortName ?? (stop.route?.longName ?? "N/A"),.bold, .caption2).foregroundColor(.white)
                            Spacer()
                        }
                        .frame(width: 35,height: 20)
                    }.frame(width: 35, height: 20, alignment: .center)
                    VStack(alignment:.leading){
                        HStack{Spacer()}
                        TextLabel("\(stop.route?.shortName ?? (stop.route?.longName ?? "N/A")) to \(stop.to?.name ?? "")").font(.footnote).foregroundColor(.gray_subtitle_color)
                            .multilineTextAlignment(.leading).lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 2)
                    }
                    .padding([.leading, .bottom], 2)
                })
            }else{
                var mode = getLegModeLabel(leg: stop)
                if stop.searchMode?.mode == Mode.scooter.rawValue {
                    mode = "Ride".localized()
                }
                let distance = stop.distance ?? 0.0
                let distanceMiles = distance*0.000621371
                var distanceMilesText = String(format: "%.1f", distanceMiles)
                let destination = stop.to?.name ?? "N/A"
                var final = "%1 %2 miles to %3".localized("\(mode)", "\(distanceMilesText)", "\(destination)")
                if distanceMilesText == "0.0"{
                    let feetValue = distanceMiles*5280
                    distanceMilesText =  String(format: "%.0f", feetValue)
                    final = "%1 %2 feet to %3".localized("\(mode)", "\(distanceMilesText)", "\(destination)")
                }
                return AnyView(VStack(alignment:.leading){
                    HStack{Spacer()}
                    if AccessibilityManager.shared.pubIsLargeFontSize {
                        VStack(alignment: .leading){
                            TextLabel(final).font(.footnote).foregroundColor(.gray_subtitle_color).lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                            VStack {
                                if accessibilityType == .accessible {
                                    HStack {
                                        Image("ic_wheelchair_black")
                                            .resizable()
                                            .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                                        Image("ic_like")
                                            .resizable()
                                            .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                                    }
                                    .foregroundStyle(Color.black)
                                    .frame(minHeight: accessibilityIconSize + 10)
                                    .padding(2)
                                    .background(color)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                    .roundedBorderWithColor(5, 0, Color.black)
                                } else if accessibilityType == .accessibilityUnknown {
                                    HStack {
                                        Image("ic_wheelchair_black")
                                            .resizable()
                                            .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                                        Image("ic_help_circle")
                                            .resizable()
                                            .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                                    }
                                    .foregroundStyle(Color.black)
                                    .frame(minHeight: accessibilityIconSize + 10)
                                    .padding(2)
                                    .background(color)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                    .roundedBorderWithColor(5, 0, Color.black)
                                } else if accessibilityType == .notAccessible {
                                    HStack {
                                        Image("ic_wheelchair_black")
                                            .resizable()
                                            .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                                        Image("ic_dislike")
                                            .resizable()
                                            .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                                    }
                                    .foregroundStyle(Color.black)
                                    .frame(minHeight: accessibilityIconSize + 10)
                                    .padding(2)
                                    .background(color)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                    .roundedBorderWithColor(5, 0, Color.black)
                                }
                            }
                        }
                    } else {
                        HStack {
                            VStack {
                                if accessibilityType == .accessible {
                                    HStack {
                                        Image("ic_wheelchair_black")
                                        Image("ic_like")
                                    }
                                    .foregroundStyle(Color.black)
                                    .frame(minHeight: 34)
                                    .padding(2)
                                    .background(color)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                    .roundedBorderWithColor(5, 0, Color.black)
                                } else if accessibilityType == .accessibilityUnknown {
                                    HStack {
                                        Image("ic_wheelchair_black")
                                        Image("ic_help_circle")
                                    }
                                    .foregroundStyle(Color.black)
                                    .frame(minHeight: 34)
                                    .padding(2)
                                    .background(color)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                    .roundedBorderWithColor(5, 0, Color.black)
                                } else if accessibilityType == .notAccessible {
                                    HStack {
                                        Image("ic_wheelchair_black")
                                        Image("ic_dislike")
                                    }
                                    .foregroundStyle(Color.black)
                                    .frame(minHeight: 34)
                                    .padding(2)
                                    .background(color)
                                    .clipShape(RoundedRectangle(cornerRadius: 5))
                                    .roundedBorderWithColor(5, 0, Color.black)
                                }
                            }
                            TextLabel(final).font(.footnote).foregroundColor(.gray_subtitle_color).lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                        }
                    }
                })
            }
        } else {
            return AnyView(VStack{
                TextLabel("Not Available")
            })
        }
    }
    
    /// Get leg mode label.
    /// - Parameters:
    ///   - leg: Parameter description
    /// - Returns: String
    private func getLegModeLabel(leg: OTPLeg) -> String {
        guard let legMode = leg.searchMode?.mode else {
            return leg.searchMode?.mode.lowercased().capitalizingFirstLetter() ?? "N/A"
        }
        switch legMode {
        case Mode.bicycle.rawValue: return "Bicycle".localized()
        case Mode.car.rawValue: return "Drive".localized()
        case Mode.gondola.rawValue: return "Aerial Tram".localized()
        case Mode.tram.rawValue:
            if let longName = leg.route?.longName?.lowercased(), longName.contains("streetcar") {
                return "Streetcar".localized()
            }
            return "Light Rail".localized()
        default:
            return leg.searchMode?.mode.lowercased().capitalizingFirstLetter() ?? "N/A"
        }
    }
    
    /// Leg steps view.
    /// - Parameters:
    ///   - leg: Parameter description
    ///   - isFirst: Parameter description
    ///   - isLast: Parameter description
    ///   - imageSize: Parameter description
    /// - Returns: some View
    private func legStepsView(leg: GraphQLTripLeg, isFirst: Bool = false, isLast: Bool = false, imageSize: CGFloat) -> some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    if AccessibilityManager.shared.pubIsLargeFontSize {
                        legStepTopViewAODA(imageSize: imageSize)
                    } else {
                        legStepTopView()
                        
                        if isExpandedDirection {
                            if let leg = leg.leg, let steps = leg.steps{
                                VStack{
                                    ForEach(Array(steps.map({GraphQLTripDirection(step: $0)}).enumerated()), id: \.offset) { index, direction in
                                        HStack {
											Image(PreviewTripManager.shared.getDirectionImage(tripDirection: direction))
                                                .resizable()
                                                .frame(width: imageSize, height: imageSize)
											TextLabel(PreviewTripManager.shared.directionDescription(tripDirection: direction))
                                                .font(.footnote)
                                                .foregroundColor(.gray_subtitle_color)
                                            Spacer()
                                        }
                                    }
                                }.padding(.bottom, 10)
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Leg step top view
    /// - Returns: some View
    /// Leg step top view.
    private func legStepTopView() -> some View  {
        HStack(alignment: .top) {
            if let leg = leg.leg, let searchMode = leg.searchMode, searchMode.mode != Mode.monorail.rawValue {
                detailsDropdownButton(leg: leg)
                Spacer()
            }
        }
    }

    /// Leg step top view a o d a.
    /// - Parameters:
    ///   - imageSize: Parameter description
    /// - Returns: some View
    private func legStepTopViewAODA(imageSize: CGFloat) -> some View  {
        VStack{
            HStack {
                if let leg = leg.leg, let searchMode = leg.searchMode, searchMode.mode != Mode.monorail.rawValue {
                    detailsDropdownButton(leg: leg)
                    Spacer()
                }
            }
            
            if isExpandedDirection {
                if let leg = leg.leg, let steps = leg.steps{
                    VStack{
                        ForEach(Array(steps.map({GraphQLTripDirection(step: $0)}).enumerated()), id: \.offset) { index, direction in
                            HStack {
								Image(PreviewTripManager.shared.getDirectionImage(tripDirection: direction))
                                    .resizable()
                                    .frame(width: imageSize, height: imageSize)
								TextLabel(PreviewTripManager.shared.directionDescription(tripDirection: direction))
                                    .font(.footnote)
                                    .foregroundColor(.gray_subtitle_color)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer()
                            }
                        }
                    }.padding(.bottom, 10)
                }
            }
        }
    }
    
    /// Leg alert view.
    /// - Parameters:
    ///   - alertsCount: Parameter description
    ///   - leg: Parameter description
    ///   - imageSize: Parameter description
    /// - Returns: some View
    private func legAlertView(alertsCount: Int, leg: OTPLeg?, imageSize: CGFloat) -> some View {
        return VStack(alignment: .leading) {
            Button(action: {
                tripPlanManager.pubCurrentTripLeg = leg
                tripPlanManager.pubIsShowingTripAlerts = true
            }, label: {
                HStack(spacing: 5){
                    Image(systemName: "exclamationmark.triangle.fill")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(Color.red)
                        .frame(width: AccessibilityManager.shared.pubIsLargeFontSize ? 35 : 25, height: AccessibilityManager.shared.pubIsLargeFontSize ? 30 : 20)
                    TextLabel("\(alertsCount) \(alertsCount > 1 ? "alerts".localized() : "alert".localized())")
                        .foregroundStyle(Color.red)
                    Image("ic_link")
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(Color.red)
                        .frame(width: AccessibilityManager.shared.pubIsLargeFontSize ? 30 : 20, height: AccessibilityManager.shared.pubIsLargeFontSize ? 30 : 20)
                }
                .padding(.bottom, 5)
            })
        }
    }
    

    
    /// Details dropdown button.
    /// - Parameters:
    ///   - leg: Parameter description
    /// - Returns: some View
    private func detailsDropdownButton(leg: OTPLeg) -> some View {
        let duration = Double(leg.duration ?? 0).format()
        let stopsCount = (leg.intermediateStops?.count ?? 0) + 1
        
        return Button(action: {
            if leg.mode != Mode.car.rawValue {
                isExpandedDirection.toggle()
            }
        }) {
            VStack{
                HStack {
                    if leg.intermediateStops?.count ?? 0 > 0 {
                        TextLabel("Ride %1 / %2 stops".localized(duration, stopsCount))
                            .font(.footnote)
                            .foregroundColor(.gray_subtitle_color)
                            .fixedSize(horizontal: false, vertical: true)
                            .multilineTextAlignment(.leading)
                        Image(isExpandedDirection  ? "ic_up" : "ic_down")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(Color.gray_subtitle_color)
                            .frame(width: AccessibilityManager.shared.pubIsLargeFontSize ? 20 : 12, height: AccessibilityManager.shared.pubIsLargeFontSize ? 20 : 12)
                        
                    } else {
                        if leg.mode == Mode.walk.rawValue {
                            TextLabel("About \(Double(leg.duration ?? 0).format())")
                                .font(.footnote)
                                .foregroundColor(.gray_subtitle_color)
                            Image(isExpandedDirection  ? "ic_up" : "ic_down")
                                .resizable()
                                .renderingMode(.template)
                                .foregroundColor(Color.gray_subtitle_color)
                                .frame(width: AccessibilityManager.shared.pubIsLargeFontSize ? 20 : 12, height: AccessibilityManager.shared.pubIsLargeFontSize ? 20 : 12)
                        } else {
                            if leg.mode != Mode.bus.rawValue {
                                TextLabel(Double(leg.duration ?? 0).format())
                                    .font(.footnote)
                                    .foregroundColor(.gray_subtitle_color)
                                if leg.mode != Mode.car.rawValue {
                                    Image(isExpandedDirection  ? "ic_up" : "ic_down")
                                        .resizable()
                                        .renderingMode(.template)
                                        .foregroundColor(Color.gray_subtitle_color)
                                        .frame(width: AccessibilityManager.shared.pubIsLargeFontSize ? 20 : 12, height: AccessibilityManager.shared.pubIsLargeFontSize ? 20 : 12)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.bottom, 10)
                if isExpandedDirection && (leg.intermediateStops?.count ?? 0 > 0){
                    ForEach(0..<(leg.intermediateStops?.count ?? 0)) { index in
                        VStack(alignment: .leading){
                            HStack{
                                Circle().fill(leg.route?.color == "ffffff" ? Color.black : Color.white)
                                    .frame(width: 4, height: 5, alignment: .center)
                                    .offset(x: -27)
                                TextLabel(leg.intermediateStops?[index].name ?? "")
                                    .font(.footnote)
                                    .foregroundColor(.gray_subtitle_color)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                            }
                            
                        }
                        
                    }
                }
            }
        }
    }
    
    /// Details dropdown button accessibility text
    /// - Returns: String
    /// Details dropdown button accessibility text.
    func detailsDropdownButtonAccessibilityText() -> String{
        let expandText = isExpandedDirection ? "collapse" : "expand"
        let duration = Double(leg.leg?.duration ?? 0).format()
        let stopsCount = (leg.leg?.intermediateStops?.count ?? 0) + 1
        let dropdownTitleText = leg.leg?.intermediateStops?.count ?? 0 > 0 ? "Ride %1 / %2 stops".localized(duration, stopsCount) : Double(leg.leg?.duration ?? 0).format()
        
        return "%1 , double tap to %2".localized(dropdownTitleText , expandText)
    }
    
    /// Trip viewer button.
    /// - Parameters:
    ///   - leg: Parameter description
    /// - Returns: some View
    private func tripViewerButton(leg: GraphQLTripLeg) -> some View {
        HStack {
            Divider()
                .frame(width: 1)
                .background(Color.black)
            Button(action: {
                if let leg = leg.leg {
                    tripViewerAction?(itinerary, leg)
                }
            }) {
                TextLabel("Trip Viewer".localized())
                    .font(.footnote)
                    .foregroundColor(themeTextColor)
            }
        }
    }
    
    /// Trip viewer button a o d a.
    /// - Parameters:
    ///   - leg: Parameter description
    /// - Returns: some View
    private func tripViewerButtonAODA(leg: GraphQLTripLeg) -> some View {
            Button(action: {
                if let leg = leg.leg {
                    StopViewerViewModel.shared.itineraryStop = leg
                    tripViewerAction?(itinerary, leg)
                }
            }) {
                HStack {
                TextLabel("Trip Viewer".localized())
                    .font(.footnote)
                    .foregroundColor(themeTextColor)
                    Spacer()
            }
        }
    }
}


extension Double {
    /// Format to time
    /// - Returns: String
    /// Formats to time.

    /// - Returns: String
    func formatToTime() -> String {
        let formatter = DateComponentsFormatter()
        var result = ""
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute]
        result = formatter.string(from: self) ?? ""
        if result == "0"{
            formatter.allowedUnits = [.second]
            return "\(formatter.string(from: self) ?? "") sec"
        }
        return "%1 min".localized(formatter.string(from: self) ?? "")
    }
}


