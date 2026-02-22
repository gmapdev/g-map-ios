//
//  TripPlanItemView.swift
//

import SwiftUI
import MapKit

struct OTPTripLeg: Identifiable, Hashable {
    let id = UUID()
    let leg: OTPLeg
    
    /// Hash.
    /// - Parameters:
    ///   - into: Parameter description
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct TripPlanItemView: View {
    @ObservedObject var tripPlanManager = TripPlanningManager.shared
    @State var isExpandedDirection = false
    @State var sortOption: SortOption
	@State var selectedItineraryIndex: Int = 0	// used to hold and select the itinrary, by default it is 0 means only one itinerary in it.
    
    let entry: GroupEntry			// used to show different time if we have.
	let isOther: Bool
    let isFull: Bool
    var action: (() -> Void)? = nil
    var stopViewerAction: ((OTPItinerary, OTPLeg) -> Void)? = nil
    var tripViewerAction: ((OTPItinerary, OTPLeg) -> Void)? = nil
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        ZStack {
            if isFull {
                detailedView.padding(.top, 10)
            }else{
                baseView()
                    .accessibilityElement(children: .combine)
            }
        }
    }
    
    /// Base view
    /// - Returns: some View
    /// Base view.
    func baseView() -> some View{
        VStack(){
            VStack(){
                tripDetails
            }
            .frame(maxWidth: UIScreen.main.bounds.size.width - 40)
        }
    }

    
    /// Detailed view.
    /// - Parameters:
    ///   - some: Parameter description
    var detailedView: some View {
        ScrollView(showsIndicators: false){
            baseView().accessibilityElement(children: .combine)
            Divider()
            VStack {
                VStack {
                    legsView
                    if AccessibilityManager.shared.pubIsLargeFontSize {
                        tripDetailInfoViewAODA
                    } else {
                        tripDetailInfoView
                    }
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal)
        }
    }
    
    /// Trip detail info view.
    /// - Parameters:
    ///   - some: Parameter description
    private var tripDetailInfoView: some View {
        // MARK: Needs to work on passing accurate Walk Duration and Bike Duration for Time Spent Active -> tool Tip.
		let (costText, _) = tripPlanManager.getItineraryCost(itinerary: entry.itineraries[selectedItineraryIndex])
		let (walkTimeText, _) = tripPlanManager.getTotalWalkTime(itinerary: entry.itineraries[selectedItineraryIndex])
        return TripDetailInfoView(dateText: tripPlanManager.milliSecondsDate(date: String(entry.itineraries[selectedItineraryIndex].startTime ?? 0)),
						   timeText: tripPlanManager.milliSecondsTimeToLocalZone(time: String(entry.itineraries[selectedItineraryIndex].startTime ?? 0)),
                           costText: costText,
                           walkTimeText: walkTimeText ?? "N/A",
                           walkDuration: tripPlanManager.getWalkingTime(itinerary: entry.itineraries[selectedItineraryIndex]),
                           bikeDuration: tripPlanManager.getCyclingTime(itinerary: entry.itineraries[selectedItineraryIndex])) // tripPlanItem.itinerary.bikeDuration
        .frame(maxWidth: ScreenSize.width() - 80)
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(radius: 3)

    }
    
    /// Trip detail info view a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    private var tripDetailInfoViewAODA: some View {
		let (costText, _) = tripPlanManager.getItineraryCost(itinerary: entry.itineraries[selectedItineraryIndex])
		let (walkTimeText, _) = tripPlanManager.getTotalWalkTime(itinerary: entry.itineraries[selectedItineraryIndex])
        return TripDetailInfoViewAODA(dateText: tripPlanManager.milliSecondsDate(date:String(entry.itineraries[selectedItineraryIndex].startTime ?? 0)),
                               timeText: tripPlanManager.milliSecondsTimeToLocalZone(time: String(entry.itineraries[selectedItineraryIndex].startTime ?? 0)),
                               costText: costText,
                               walkTimeText: walkTimeText ?? "N/A",
                               walkDuration: tripPlanManager.getWalkingTime(itinerary: entry.itineraries[selectedItineraryIndex]),
                               bikeDuration: tripPlanManager.getCyclingTime(itinerary: entry.itineraries[selectedItineraryIndex]), imageSize: AccessibilityManager.shared.getFontSize()) // tripPlanItem.itinerary.bikeDuration
        .frame(maxWidth: ScreenSize.width() - 80)
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 3)
    }
	
    /// Trip details.
    /// - Parameters:
    ///   - some: Parameter description
    private var tripDetails: some View {
        return VStack(){
			if let legs = entry.itineraries[selectedItineraryIndex].legs, legs.count > 0 {
				ItineraryItemView(isOther: isOther, selectedItineraryIndex:$selectedItineraryIndex, entry: self.entry)
            }
        }
    }

    /// Legs view.
    /// - Parameters:
    ///   - some: Parameter description
    private var legsView: some View {
		let itinerary = entry.itineraries[selectedItineraryIndex]
		var legsView = ItineraryLegsView(itinerary: itinerary)
		legsView.stopViewerAction = { itinerary, leg in
			stopViewerAction?(itinerary, leg)
		}
		legsView.tripViewerAction = { itinerary, leg in
			tripViewerAction?(itinerary, leg)
		}
        return legsView
    }
}

struct ItineraryItemView: View{
    @ObservedObject var tripPlanManager = TripPlanningManager.shared
    @State var isOther: Bool
    @State var lastMode: Mode?
	@State var selectedTime: String?
	@Binding var selectedItineraryIndex: Int
    
	let entry: GroupEntry
    let columns = [GridItem(.flexible(minimum: 60, maximum: 100))]
    var modeManager = ModeManager.shared

    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
        let accessibilityIconSize = AccessibilityManager.shared.pubIsLargeFontSize ? (AccessibilityManager.shared.getFontSize()*0.65) : 20
        if !isOther{
            let (accessibilityType, color) = tripPlanManager.getaccessibilityConfidenceForItinerary(itinerary: entry.itineraries[selectedItineraryIndex])
			VStack(alignment: .leading){

                if accessibilityType != .noInfo {
                    HStack {
                        if accessibilityType == .accessible {
                            HStack {
                                Image("ic_wheelchair_black")
                                    .resizable()
                                    .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                                Image("ic_like")
                                    .resizable()
                                    .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                                Spacer()
                            }
                        } else if accessibilityType == .accessibilityUnknown {
                            HStack {
                                Image("ic_wheelchair_black")
                                    .resizable()
                                    .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                                Image("ic_help_circle")
                                    .resizable()
                                    .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                                Spacer()
                            }
                        } else if accessibilityType == .notAccessible {
                            HStack {
                                Image("ic_wheelchair_black")
                                    .resizable()
                                    .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                                Image("ic_dislike")
                                    .resizable()
                                    .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                                Spacer()
                            }
                        }
                    }
                    .padding(.leading, 5)
                    .frame(minHeight: accessibilityIconSize + 10)
                    .background(color)
                }else {
                    Spacer().frame(height: 10)
                }
                VStack(alignment: .leading){
                    if AccessibilityManager.shared.pubIsLargeFontSize {
                        topInfoViewAODA
                    } else {
                        topInfoView
                    }
                    
                    TransportsView(itinerary: entry.itineraries[selectedItineraryIndex])
                    
                    Divider()
                    
                    leaveAtTimeText(selectedTime)
                }.padding(.horizontal, 10)
                    .padding(.bottom, 5)
				
            }.frame(minHeight: 150)

        }else{
		
            if AccessibilityManager.shared.pubIsLargeFontSize {
                otherGroupViewAODA
            } else {
                otherGroupView
            }
        }
    }
    
    /// Other group view.
    /// - Parameters:
    ///   - some: Parameter description
    var otherGroupView: some View {
        let accessibilityIconSize = AccessibilityManager.shared.pubIsLargeFontSize ? (AccessibilityManager.shared.getFontSize()*0.65) : 20
        let (accessibilityType, color) = tripPlanManager.getaccessibilityConfidenceForItinerary(itinerary: entry.itineraries[selectedItineraryIndex])
		let (timeText, _) = tripPlanManager.timeText(for: String(entry.itineraries[selectedItineraryIndex].duration ?? 0))
        return VStack{
            if accessibilityType != .noInfo {
                HStack{
                    if accessibilityType == .accessible {
                        HStack {
                            Image("ic_wheelchair_black")
                                .resizable()
                                .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                            Image("ic_like")
                                .resizable()
                                .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                            Spacer()
                        }
                    } else if accessibilityType == .accessibilityUnknown {
                        HStack {
                            Image("ic_wheelchair_black")
                                .resizable()
                                .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                            Image("ic_help_circle")
                                .resizable()
                                .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                            Spacer()
                        }
                    } else if accessibilityType == .notAccessible {
                        HStack {
                            Image("ic_wheelchair_black")
                                .resizable()
                                .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                            Image("ic_dislike")
                                .resizable()
                                .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                            Spacer()
                        }
                    }
                }
                .padding(.leading, 5)
                .frame(minHeight: accessibilityIconSize + 10)
                .background(color)
            }else {
                Spacer().frame(height: 5)
            }
            Spacer()
            HStack(alignment:.center){
                if let leg = otherGroupSectionMode(legs: entry.itineraries[selectedItineraryIndex].legs) {
                    VStack{
                        Image(modeManager.getImageIconforSearchRoute(leg: leg))
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(3)
                            .foregroundColor( (leg.mode ?? "" == "BICYCLE_RENT") ? Color.black :  Color.white)
                    }
                    .frame(width: 40, height: 40).background((leg.mode ?? "" == "BICYCLE_RENT") ? Color.clear : Color.black)
                    .cornerRadius(5)
                }
                
                TextLabel(ModeManager.shared.consolidateModes(otherGroupSectionMode(legs: entry.itineraries[selectedItineraryIndex].legs)?.mode ?? ""))
                    .font(.body)
                    .foregroundColor(Color.black)
                
                Spacer()
                
                TextLabel(timeText, .bold, .title2)
                    .foregroundColor(Color.black)
                    .addAccessibility(text: MapManager.shared.pubIsInTripPlanDetail ? "%1".localized(entry.itineraries[selectedItineraryIndex].duration ?? "") : "%1. Double tap for more details".localized(entry.itineraries[selectedItineraryIndex].duration ?? ""))
                
            }
            .padding(.horizontal, 10)
            Spacer()
        }.frame(minHeight: accessibilityType != .noInfo ? (60 + accessibilityIconSize) : (60 + accessibilityIconSize))
    }
    
    /// Other group view a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    var otherGroupViewAODA: some View {
        let accessibilityIconSize = AccessibilityManager.shared.pubIsLargeFontSize ? (AccessibilityManager.shared.getFontSize()*0.65) : 20
        let (accessibilityType, color) = tripPlanManager.getaccessibilityConfidenceForItinerary(itinerary: entry.itineraries[selectedItineraryIndex])
		let (timeText, _) = tripPlanManager.timeText(for: String(entry.itineraries[selectedItineraryIndex].duration ?? 0))
        return HStack {
            VStack(alignment: .leading){
                if accessibilityType != .noInfo {
                    HStack {
                        if accessibilityType == .accessible {
                            HStack {
                                Image("ic_wheelchair_black")
                                    .resizable()
                                    .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                                Image("ic_like")
                                    .resizable()
                                    .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                                Spacer()
                            }
                        } else if accessibilityType == .accessibilityUnknown {
                            HStack {
                                Image("ic_wheelchair_black")
                                    .resizable()
                                    .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                                Image("ic_help_circle")
                                    .resizable()
                                    .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                                Spacer()
                            }
                        } else if accessibilityType == .notAccessible {
                            HStack {
                                Image("ic_wheelchair_black")
                                    .resizable()
                                    .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                                Image("ic_dislike")
                                    .resizable()
                                    .frame(width: accessibilityIconSize, height: accessibilityIconSize)
                                Spacer()
                            }
                        }
                    }
                    .padding(.leading, 5)
                    .frame(minHeight: accessibilityIconSize + 10)
                    .background(color)
                }else {
                    Spacer().frame(height: 10)
                }
                VStack(alignment: .leading){
                if let leg = otherGroupSectionMode(legs: entry.itineraries[selectedItineraryIndex].legs) {
                    VStack{
                        Image(modeManager.getImageIconforSearchRoute(leg: leg))
                            .renderingMode(.template)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(3)
                            .foregroundColor( (leg.mode ?? "" == "BICYCLE_RENT") ? Color.black :  Color.white)
                    }
                    .frame(width: AccessibilityManager.shared.pubIsLargeFontSize ? AccessibilityManager.shared.getFontSize() : 40, height: AccessibilityManager.shared.pubIsLargeFontSize ? AccessibilityManager.shared.getFontSize() : 40).background((leg.mode ?? "" == "BICYCLE_RENT") ? Color.clear : Color.black)
                    .cornerRadius(5)
                }
                
                TextLabel(ModeManager.shared.consolidateModes(otherGroupSectionMode(legs: entry.itineraries[selectedItineraryIndex].legs)?.mode ?? ""))
                    .font(.body)
                    .foregroundColor(Color.black)
                
                Spacer()
                
                    TextLabel(timeText, .bold, .title2)
                    .foregroundColor(Color.black)
                    .addAccessibility(text: MapManager.shared.pubIsInTripPlanDetail ? "%1".localized(entry.itineraries[selectedItineraryIndex].duration ?? "") : "%1. Double tap for more details".localized(entry.itineraries[selectedItineraryIndex].duration ?? ""))
                
            }.padding(.horizontal, 10)
        }
        }

    }
    
    /// Top info view.
    /// - Parameters:
    ///   - some: Parameter description
    var topInfoView: some View {
	   let (costText, _) = tripPlanManager.getItineraryCost(itinerary: entry.itineraries[selectedItineraryIndex])
		let (timeText, _) = tripPlanManager.timeText(for: String(entry.itineraries[selectedItineraryIndex].duration ?? 0))
       return  HStack{
            TextLabel(timeText, .bold, .title2)
                .foregroundColor(Color.black)

            Spacer()

            TextLabel("%1 walking".localized(walkingTime))
                .font(.body)
                .foregroundColor(Color.black)

            Spacer().frame(width: 10)
        }
    }
    
    /// Top info view a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    var topInfoViewAODA: some View {
		let (costText, _) = tripPlanManager.getItineraryCost(itinerary: entry.itineraries[selectedItineraryIndex])
		let (timeText, _) = tripPlanManager.timeText(for: String(entry.itineraries[selectedItineraryIndex].duration ?? 0))
        return VStack(alignment: .leading){
            TextLabel(timeText, .bold, .title2)
                .foregroundColor(Color.black)
            TextLabel("%1 walking".localized(walkingTime))
                .font(.body)
                .foregroundColor(Color.black)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

	
	// this function is used to filter the one with walk mode + bikeshare mode, but we skip the bikeshare mode.
 /// Other group section mode.
 /// - Parameters:
 ///   - legs: [OTPLeg]?
 /// - Returns: OTPLeg?
	private func otherGroupSectionMode(legs: [OTPLeg]?)-> OTPLeg? {
		if let legs = legs {
			if legs.count == 1 {
				return legs[0]
			}else {
				for leg in legs {
					if let mode = leg.searchMode?.mode {
						if mode != Mode.walk.rawValue {
							// speically treat the rented bike.
							if let rentedBike = leg.rentedBike, mode == Mode.bicycle.rawValue && rentedBike  {
								var newLeg = leg
								newLeg.mode = "BICYCLE_RENT"
								return newLeg
							}
							
							return leg
						}
					}
				}
			}
		}
		return nil
	}

    /// Walking time.
    /// - Parameters:
    ///   - String: Parameter description
    private var walkingTime: String {
        var time: TimeInterval = 0
		if let legs = entry.itineraries[selectedItineraryIndex].legs {
			for leg in legs{
				if (leg.searchMode?.mode ?? "") == "WALK"{
					time += Double(leg.duration ?? 0)
				}
			}
		}
        time = floor(time/60)

        let hours = Int(time)/60
        let minutes = Int(time)%60
        var walkingTime = ""
        if hours > 0 {
            walkingTime = "%1 hrs".localized(hours) + " "
        }
        if minutes > 0 {
            walkingTime += "%1 min".localized(minutes)
        }else {
            walkingTime += "%1 min".localized("0")
        }

        return walkingTime
    }
	
    /// Get real time status.
    /// - Parameters:
    ///   - legs: Parameter description
    /// - Returns: Bool
    private func getRealTimeStatus(legs: [OTPLeg]) -> Bool {
        var isRealTime = false
        let transitModes = [Mode.transit, Mode.bus, Mode.tram, Mode.ferry, Mode.rail, Mode.streetcar, Mode.water_taxi, Mode.rent, Mode.subway, Mode.car_park, Mode.car_hail, Mode.car_rent, Mode.carpool, Mode.airplane, Mode.gondola, Mode.funicular, Mode.light_rail, Mode.monorail, Mode.link, Mode.cableCar, Mode.linkLightRail]
        var transitLegs: [OTPLeg] = []
        for leg in legs {
            if let searchMode = leg.searchMode {
                if transitModes.contains(where: {$0.rawValue == searchMode.mode}) {
                    transitLegs.append(leg)
                }
            }
        }
        if !transitLegs.isEmpty {
            isRealTime = isRealTime || transitLegs[0].realTime ?? false
        }
        
        return isRealTime
    }

 /// Leave at time text.
 /// - Parameters:
 ///   - _: Parameter description
 /// - Returns: some View
	private func leaveAtTimeText(_ selectedTime: String? = nil) -> some View {
		var voiceoverText = ""
        var realTimeDict = [String: Bool]()
		
		if entry.itineraries.count > 0 {
			voiceoverText = "You leave ".localized()
			
			if TripPlanningManager.shared.pubSortOption == .arrivalTime {
					voiceoverText = "You arrive ".localized()
			}
		}
		
		// this container will remember all the duplicated start time, so that we can filter.
		var leaveTimeContainer = [String]()
		
		// internal use of the structure to track the time and itinerary
		struct ClickableTime {
			var leaveAtTime: String
			var itinerary: OTPItinerary
		}
		
		var clickableTimeLabels = [ClickableTime]()
		var clickableWords = [String]()
		var underlineWords = [String]()
		
        for index in 0..<entry.itineraries.count {
            var startTime = TimeInterval(entry.itineraries[index].startTime ?? 0)
			if TripPlanningManager.shared.pubSortOption == .arrivalTime {
				startTime = TimeInterval(entry.itineraries[index].endTime ?? 0)
			}
            if !leaveTimeContainer.contains(startTime.milliSecondsTimeToLocalZone()){
                clickableTimeLabels.append(ClickableTime(
                    leaveAtTime: startTime.milliSecondsTimeToConfigTimeZone(),
                    itinerary: entry.itineraries[index])
                )
                leaveTimeContainer.append(startTime.milliSecondsTimeToLocalZone())
            }
            
            // Check realtime status for each trip legs
            if let legs = entry.itineraries[index].legs, legs.count > 0{
                var newRealTimeStatus = getRealTimeStatus(legs: legs)
                realTimeDict[startTime.milliSecondsTimeToConfigTimeZone()] = newRealTimeStatus
            }
        }
		
		for index in 0..<clickableTimeLabels.count {
            
            
			if index == clickableTimeLabels.endIndex - 1 {
				if index != 0 {
                    voiceoverText += " or ".localized()
				}else{
					if clickableTimeLabels.count > 1 {
						voiceoverText += ", "
					}
				}
			}else{
				if index != 0 {
					voiceoverText += ", "
				}
			}
			
			clickableWords.append(clickableTimeLabels[index].leaveAtTime)
			voiceoverText += clickableTimeLabels[index].leaveAtTime
		}
		
		underlineWords = clickableWords
		if let selectedTime = selectedTime {
			underlineWords = underlineWords.filter({ $0 != selectedTime })
		}else{
			if underlineWords.count > 0 {
				underlineWords.remove(at: 0)
			}
		}
  /// Hex: "#000000"
  /// Initializes a new instance.
  /// - Parameters:
  ///   - hex: "#000000"
		let highlighColor = Color.init(hex: "#000000")
  /// Hex: "#666666"
  /// Initializes a new instance.
  /// - Parameters:
  ///   - hex: "#666666"
		let defaultColor = Color.init(hex: "#666666")
		return ClickableText(voiceoverText, clickableWords, underlineWords, highlighColor, defaultColor, realTimeDict) { word in
			self.selectedTime = word
			var index = 0
			for i in 0..<entry.itineraries.count {
                let itinerary = entry.itineraries[i]
                var stTime = TimeInterval(itinerary.startTime ?? 0).milliSecondsTimeToLocalZone()
				if TripPlanningManager.shared.pubSortOption == .arrivalTime {
					stTime = TimeInterval(itinerary.endTime ?? 0).milliSecondsTimeToLocalZone()
				}
                if stTime == word {
                    index = i
                    break
                }
            }
			self.selectedItineraryIndex = index
            ProfileManager.shared.selectedItinerary = entry.itineraries[index]
		}
        .addAccessibility(text: voiceoverText.localized())
	}
    
}
