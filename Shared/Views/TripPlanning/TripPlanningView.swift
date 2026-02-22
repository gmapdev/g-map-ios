//
//  TripPlanningView.swift
//

import SwiftUI
import CryptoKit

// This is used to define the section label for the search itinerary list. based on web logic, only those five group will be existed.
enum GroupSectionLabel: String {
	case bike = "Bike"
	case bikeshare = "Bikeshare"
	case drive = "Drive"
	case driveshare = "Driveshare"
	case transit = "Transit"
    case scooter = "E-Scooter"
	case walk = "Walk"
}

// This is used to hold each entry in the group, so that we can hold a set of same itineraries in one entry and present to user.
struct GroupEntry: Identifiable {
	public var id = UUID()
	public var entryKey: String	// this key normally is generated based on legs mode and route number.
	public var itineraries: [OTPItinerary]
}

struct TripPlanningView: View {
    
    @ObservedObject var tripPlanManager = TripPlanningManager.shared
    @ObservedObject var mapFromToModel = MapFromToViewModel.shared
    var showDetailsAction: ((GroupEntry, OTPItinerary) -> Void)? = nil
    var selectedItinerary: ((OTPItinerary) -> Void)? = nil
    var stopViewerAction: ((OTPItinerary, OTPLeg) -> Void)? = nil
    var tripViewerAction: ((OTPItinerary, OTPLeg) -> Void)? = nil
    var backAction: (() -> Void)? = nil
    
    
    /// Body.
    /// - Parameters:
    ///   - some: Parameter description
    var body: some View {
       
        ZStack(alignment: .topTrailing) {
            VStack {
                Spacer().frame(height: ScreenSize.safeTop() + 30)
                if AccessibilityManager.shared.pubIsLargeFontSize {
                    listViewAODA
                }else {
                    listView
                }
            }
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    /// Back button.
    /// - Parameters:
    ///   - some: Parameter description
    private var backButton: some View {
        Button(action: {
			backAction?()
        }, label: {
            Image("ic_leftarrow")
                .renderingMode(.template)
                .resizable()
                .padding(5)
                .foregroundColor(.black)
        })
        .frame(width: 25, height: 30)
        .padding([.top, .leading],10)
        .accessibilityLabel(Text(AvailableAccessibilityItem.backButton.rawValue.localized()).font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size)))
    }
    
    /// Back button a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    private var backButtonAODA: some View {
        Button(action: {
			backAction?()
        }, label: {
            Spacer()
            TextLabel("Back")
                .foregroundColor(Color.black)
            Spacer()
        })
        .padding(10)
        .background(Color.white)
        .cornerRadius(10)
        .accessibilityLabel(Text(AvailableAccessibilityItem.backButton.rawValue.localized()).font(Font.custom(CustomFontWeight.regular.fontName, size: CustomFontStyle.body.size)))
    }
    
    /// List view.
    /// - Parameters:
    ///   - some: Parameter description
    private var listView: some View {
        return VStack {
            HStack(alignment: .top){
                HStack(alignment: .top){
                    backButton
                }.padding(.top, 5)
                VStack{
                    HStack{
                        Image("ic_origin")
                            .resizable()
                            .frame(width: 20, height: 20, alignment: .center)
                        
                        TextLabel(mapFromToModel.pubFromDisplayString)
                            .foregroundColor(.black)
                            .font(.body)
                            .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }.frame(maxHeight: 50)
                        .addAccessibility(text: "Origin, %1".localized(mapFromToModel.pubFromDisplayString))
                    HStack{
                        Image("ic_destination")
                            .resizable()
                            .frame(width: 22, height: 22, alignment: .leading)
                        
                        TextLabel(mapFromToModel.pubToDisplayString)
                            .foregroundColor(.black)
                            .font(.body)
                            .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                        Spacer()
                    }.frame(maxHeight: 50)
                        .addAccessibility(text: "Destination, %2".localized(mapFromToModel.pubToDisplayString))
                        .offset(x: -1)
                }.frame(maxHeight: 100)
                .padding(.vertical)
            }.frame(maxHeight: 100)
                .background(Color.white)
                .cornerRadius(10)
                .padding(.horizontal)
            Divider()
                .frame(height: 2)
                .background(Color.white)
                .padding(.vertical)
            
            TripPlanToolBarView()
                .padding(.bottom, 5)
                .padding(.horizontal)
			ScrollView {
				VStack {
                    if !tripPlanManager.graphQLRoutingErrors.isEmpty && !tripPlanManager.pubIsStillLoadingItineraries {
                        ForEach(tripPlanManager.graphQLRoutingErrors) { error in
                            HStack {
                                Image("ic_exclamation")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                Spacer().frame(width: 10)
                                VStack {
                                    HStack{
                                        TextLabel(error.displayText.localized(), .bold , .title2)
                                            .foregroundColor(Color.white)
                                            .multilineTextAlignment(.leading)
                                        Spacer()
                                    }
                                    Spacer().frame(height: 5)
                                    HStack{
                                        TextLabel(error.displaySubText.localized(), .bold, .body)
                                            .foregroundColor(Color.white)
                                            .multilineTextAlignment(.leading)
                                        Spacer()
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                    groupListView()
                    if tripPlanManager.pubIsStillLoadingItineraries {
                        TextLabel("Loading itineraries...".localized(), .bold, .title2)
                            .foregroundStyle(Color.white)
                            .padding()
                    }
				}
				.background(Color.main)
				.clipShape(RoundedRectangle(cornerRadius: 10))
				.padding(.bottom, 50)
			}
            Spacer()
        }
        .edgesIgnoringSafeArea(.bottom)
    }
    
    /// List view a o d a.
    /// - Parameters:
    ///   - some: Parameter description
    private var listViewAODA: some View {
        return ScrollView {
            VStack {
                backButtonAODA
                    .padding(.horizontal)
                Spacer().frame(height: 10)
                HStack(alignment: .top){
                    VStack{
                        HStack{
                            VStack {
                                Image("ic_origin")
                                    .resizable()
                                    .frame(width: AccessibilityManager.shared.getFontSize()/2, height: AccessibilityManager.shared.getFontSize()/2, alignment: .center)
                                    .padding(.top, 5)
                                Spacer()
                            }
                            TextLabel(mapFromToModel.pubFromDisplayString)
                                .foregroundColor(.black)
                                .font(.body).fixedSize(horizontal: false, vertical: true)
                            Spacer()
                        }
                        .addAccessibility(text: "Origin, %1".localized(mapFromToModel.pubFromDisplayString))
                        HorizontalLine(color: Color.black)
                            .padding(.trailing, 10)
                        HStack{
                            VStack {
                                Image("ic_destination")
                                    .resizable()
                                    .frame(width: AccessibilityManager.shared.getFontSize()/2, height: AccessibilityManager.shared.getFontSize()/2, alignment: .center)
                                    .padding(.top, 5)
                                Spacer()
                            }
                            TextLabel(mapFromToModel.pubToDisplayString)
                                .foregroundColor(.black)
                                .font(.body).fixedSize(horizontal: false, vertical: true)
                            Spacer()
                        }
                        .addAccessibility(text: "Destination, %2".localized(mapFromToModel.pubToDisplayString))
                    }
                    .padding(.vertical)
                    .padding(.leading, 10)
                }
                .background(Color.white)
                .cornerRadius(10)
                .padding(.horizontal)
                Divider()
                    .frame(height: 2)
                    .background(Color.white)
                    .padding(.vertical)
                
                TripPlanToolBarView()
                    .padding(.bottom, 5)
                    .padding(.horizontal, 10)
                
                ScrollView {
                    VStack {
                        if !tripPlanManager.graphQLRoutingErrors.isEmpty && !tripPlanManager.pubIsStillLoadingItineraries {
                            ForEach(tripPlanManager.graphQLRoutingErrors) { error in
                                HStack {
                                    Image("ic_exclamation")
                                        .resizable()
                                        .frame(width: AccessibilityManager.shared.getFontSize(), height: AccessibilityManager.shared.getFontSize())
                                    Spacer().frame(width: 10)
                                    VStack {
                                        HStack{
                                            TextLabel(error.displayText.localized(), .bold)
                                                .font(.system(size: AccessibilityManager.shared.getFontSize()-5))
                                                .foregroundColor(Color.white)
                                                .multilineTextAlignment(.leading)
                                            Spacer()
                                        }
                                        Spacer().frame(height: 5)
                                        HStack{
                                            TextLabel(error.displaySubText.localized(), .bold)
                                                .foregroundColor(Color.white)
                                                .multilineTextAlignment(.leading)
                                            Spacer()
                                        }
                                    }
                                }
                                .padding()
                            }
                        }
                        groupListView()
                        if tripPlanManager.pubIsStillLoadingItineraries {
                            TextLabel("Loading itineraries...".localized(), .bold, .title2)
                                .foregroundStyle(Color.white)
                                .padding()
                        }
                    }
                    .background(Color.main)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.bottom, 50)
                }
                Spacer()
            }
            .background(Color.main)
            .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    
    /// Item view.
    /// - Parameters:
    ///   - _: Parameter description
    ///   - isOther: Parameter description
    /// - Returns: TripPlanItemView
    private func itemView(_ item: GroupEntry, isOther: Bool) -> TripPlanItemView {
        var itemView = TripPlanItemView(
			sortOption: TripPlanningManager.shared.pubSortOption, entry: item, isOther: isOther, isFull: false)
        itemView.stopViewerAction = { itinerary, leg in
            stopViewerAction?(itinerary, leg)
        }
        itemView.tripViewerAction = { itinerary, leg in
            tripViewerAction?(itinerary, leg)
        }
        
        return itemView
    }
	
 /// Group view.
 /// - Parameters:
 ///   - _: Parameter description
 ///   - title: Parameter description
 /// - Returns: some View
	func groupView(_ entries: [GroupEntry], title: String) -> some View {
		VStack{
			if entries.count > 0 {
				HStack{
                    TextLabel(title.localized(), .bold, .headline).foregroundColor(.white)
					Spacer()
				}.accessibilityAddTraits(.isHeader)
                    .padding(.horizontal, 10)
				groupItemsView(entries: entries, isOther: title.split(separator: "+").count == 1)
			}
			else{
				EmptyView()
			}
		}
	}
	
	// This function will return all the modes appeared in the legs.
 /// Legs mode.
 /// - Parameters:
 ///   - legs: [OTPLeg]?
 /// - Returns: [String]
	func legsMode(_ legs: [OTPLeg]?) -> [String] {
		guard let legs = legs else {
			return []
		}
		var appearedModes = [String]()
		for leg in legs {
            if let mode = leg.searchMode?.mode {
				var processedMode = mode
				
				// Special checking for bike rental.Since server won't return BICYCLE_RENT to us
				if let isRent = leg.rentedBike, isRent && processedMode == Mode.bicycle.rawValue {
					processedMode = "BICYCLE_RENT"
				}
				
				let conMode = ModeManager.shared.consolidateModes(processedMode)
				if !appearedModes.contains(conMode){
					appearedModes.append(conMode)
				}
			}
		}
		return appearedModes
	}
	
	// This function is used to compare two set of modes, and return if the requiredModes are in the legsModes.
 /// Match legs mode.
 /// - Parameters:
 ///   - legs: [OTPLeg]?
 ///   - requiredModes: [String]
 /// - Returns: Bool
	func matchLegsMode(_ legs: [OTPLeg]?, requiredModes: [String]) -> Bool {
		var modeExisted = true
		let originalLegModes = legsMode(legs)
		if originalLegModes.count == requiredModes.count {
			for legMode in originalLegModes {
				if !requiredModes.contains(legMode) {
					modeExisted = false
					break
				}
			}
		}
		return modeExisted
	}
	
 /// Generate mode key.
 /// - Parameters:
 ///   - _: Parameter description
 /// - Returns: String
	func generateModeKey(_ modes: [String]) -> String {
		var newModesLabel = modes
		if newModesLabel.contains(GroupSectionLabel.drive.rawValue) || newModesLabel.contains(GroupSectionLabel.driveshare.rawValue) {
			newModesLabel = newModesLabel.filter { mode in
				return mode != GroupSectionLabel.walk.rawValue
			}
		}else if newModesLabel.contains(GroupSectionLabel.bike.rawValue) || newModesLabel.contains(GroupSectionLabel.bikeshare.rawValue) {
			newModesLabel = newModesLabel.filter { mode in
				return mode != GroupSectionLabel.walk.rawValue
			}
        }else if newModesLabel.contains(GroupSectionLabel.scooter.rawValue){
            newModesLabel = newModesLabel.filter{ mode in
                return mode != GroupSectionLabel.walk.rawValue
            }
        }

		
		if newModesLabel.contains(GroupSectionLabel.transit.rawValue) {
			newModesLabel.removeAll { mode in return mode == GroupSectionLabel.transit.rawValue }
			newModesLabel.append(GroupSectionLabel.transit.rawValue)
		}
		
		if newModesLabel.count == 1  && newModesLabel.contains(GroupSectionLabel.transit.rawValue){
			newModesLabel.insert(contentsOf: [GroupSectionLabel.walk.rawValue], at: 0)
		}
		
		return newModesLabel.joined(separator: " + ")
	}
	
	
	
	/// this is used to generate the entry key to decide to itinerary is the same or not. if the itinereary is the same just different timing, there key will be the same and we need to group.
 /// Retrieve itinerary entry key.
 /// - Parameters:
 ///   - itinerary: OTPItinerary
 /// - Returns: String
	func retrieveItineraryEntryKey(_ itinerary: OTPItinerary) -> String {
		guard let legs = itinerary.legs else {
			return itinerary.id
		}
		var groupEntryKey = ""
		for leg in legs {
			let fromName = leg.from?.name ?? ""
			let toName = leg.to?.name ?? ""
            let mode = leg.searchMode?.mode ?? ""
			let shortName = leg.route?.shortName ?? ""
			let longName = leg.route?.longName ?? ""
			groupEntryKey += "\(fromName)\(toName)\(mode)\(shortName)\(longName)"
		}
		let hashed = SHA256.hash(data: Data(groupEntryKey.utf8))
		return hashed.compactMap { String(format: "%02x", $0) }.joined()
	}
	
 /// Generate group entries.
 /// - Parameters:
 ///   - _: Parameter description
 /// - Returns: [GroupEntry]
	func generateGroupEntries(_ itineraries: [OTPItinerary]) -> [GroupEntry] {
		var groupEntries = [String: GroupEntry]()
		for itinerary in itineraries {
			let groupEntryKey = retrieveItineraryEntryKey(itinerary)
			if groupEntries[groupEntryKey] == nil {
				groupEntries[groupEntryKey] = GroupEntry(entryKey: groupEntryKey, itineraries: [OTPItinerary]())
			}
			groupEntries[groupEntryKey]?.itineraries.append(itinerary)
		}
		
		return groupEntries.map { $0.value }
	}
    
    /// Group list view
    /// - Returns: some View
    /// Group list view.
    func groupListView() -> some View {
		var modeGroups = [String: [OTPItinerary]]()
        for itinerary in tripPlanManager.pubItineraries {
			let legs = itinerary.legs
			let lModes = legsMode(legs)
			if lModes.count > 0 {
				let modesKey = generateModeKey(lModes)
				if modeGroups[modesKey] == nil{
					modeGroups[modesKey] = [OTPItinerary]()
				}
				
				if let tpItems = modeGroups[modesKey] {
					if !tpItems.contains(itinerary) {
						modeGroups[modesKey]?.append(itinerary)
					}
				}
			}
        }
		
		// Second level group checking for entries. remember, GroupEntry is a set of similar itineraries. normally, GroupEntry is Itinerary
		
		var groupEntriesForMode = [String: [GroupEntry]]()
		for group in modeGroups {
			let itineraries = group.value
			groupEntriesForMode[group.key] = generateGroupEntries(itineraries)
		}
		
		// sort the entries for each group
		for (key, value) in groupEntriesForMode {
			var newEntries = value
			newEntries.sort { pre, nxt in
				return OTPComparator.shared.itineraryComparator(pre.itineraries[0], nxt.itineraries[0])
			}
			groupEntriesForMode[key] = newEntries
		}
		
		// Sort for the group section label
		let preSortedGroups = groupEntriesForMode.sorted { pre, nxt in
			return OTPComparator.shared.groupSortComparator(pre, nxt)
		}
		
		var combinedSortedGroups = [String: [GroupEntry]]()
		for group in preSortedGroups {
			if group.key.components(separatedBy: "+").count == 1 {
				if combinedSortedGroups["Other"] == nil {
					combinedSortedGroups["Other"] = [GroupEntry]()
				}
                combinedSortedGroups["Other"]?.append(contentsOf: group.value)
			}else{
				combinedSortedGroups[group.key] = group.value
			}
		}
        
        // sort the entries for Other group
        for (key, value) in combinedSortedGroups {
            if key == "Other" {
                var newEntries = value
                newEntries.sort { pre, nxt in
                    return OTPComparator.shared.itineraryComparator(pre.itineraries[0], nxt.itineraries[0])
                }
                combinedSortedGroups[key] = newEntries
            }
        }
		
		// Sort for the group section label
		let sortedGroups = combinedSortedGroups.sorted { pre, nxt in
			return OTPComparator.shared.groupSortComparator(pre, nxt)
		}
		
		
        // for the count of total Search Itineraries
        var totalItineraries = 0
        for(_, values) in sortedGroups{
            totalItineraries += values.count
        }
        tripPlanManager.toolbarModel.text = DataFormatter.convert(totalItineraries)
        
        return VStack{
			ForEach(sortedGroups, id: \.key) { sortedGroup in
				groupView(sortedGroup.value, title: sortedGroup.key)
			}
        }
    }
    
    /// Group items view.
    /// - Parameters:
    ///   - entries: Parameter description
    ///   - isOther: Parameter description
    /// - Returns: some View
    func groupItemsView(entries: [GroupEntry], isOther: Bool) -> some View {
        VStack(spacing: 10){
            ForEach(entries) { item in
                itemView(item, isOther: isOther)
                    .background(Color.white)
                    .cornerRadius(10)
                    .onTapGesture {
                        let defaultSelectedItinerary = item.itineraries[0]
                        tripPlanManager.pubSelectedGroupEntry = item
                        tripPlanManager.didSelectItem(defaultSelectedItinerary)
                        tripPlanManager.pubSelectedItinerary = defaultSelectedItinerary
                        let planTripItem = OTPPlanTrip(itineraries: [defaultSelectedItinerary])
                        tripPlanManager.pubSelectedTripPlanItem = planTripItem
                        selectedItinerary?(defaultSelectedItinerary)
                        showDetailsAction?(item, defaultSelectedItinerary)
                        ProfileManager.shared.tripManagerState = .creation
                        ProfileTripModel.shared.clearTripModel()
                        ProfileManager.shared.selectedItinerary = tripPlanManager.pubSelectedItinerary
                        ProfileManager.shared.selectedGraphQLTripPlan = tripPlanManager.pubSelectedTripPlanItem
                        FareTableManager.shared.pubSelectedItinerary = tripPlanManager.pubSelectedItinerary
                        if let selectedItinerary = tripPlanManager.pubSelectedItinerary{
                            FareTableManager.shared.pubItineraryCategorisedFares = tripPlanManager.calculateLegCost(itinerary: selectedItinerary)
                        }
                        MapManager.shared.pubIsInTripPlanDetail = true
                        
                        MapManager.shared.pubHideAddressBar = true
                        withAnimation {
                            tripPlanManager.pubShowFullPage = false
                        }
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityAction {
                        let defaultSelectedItinerary = item.itineraries[0]
                        tripPlanManager.pubSelectedGroupEntry = item
                        tripPlanManager.didSelectItem(defaultSelectedItinerary)
                        tripPlanManager.pubSelectedItinerary = defaultSelectedItinerary
                        let planTripItem = OTPPlanTrip(itineraries: [defaultSelectedItinerary])
                        tripPlanManager.pubSelectedTripPlanItem = planTripItem
                        selectedItinerary?(defaultSelectedItinerary)
                        showDetailsAction?(item, defaultSelectedItinerary)
                        ProfileManager.shared.tripManagerState = .creation
                        ProfileTripModel.shared.clearTripModel()
                        ProfileManager.shared.selectedItinerary = tripPlanManager.pubSelectedItinerary
                        ProfileManager.shared.selectedGraphQLTripPlan = tripPlanManager.pubSelectedTripPlanItem
                        FareTableManager.shared.pubSelectedItinerary = tripPlanManager.pubSelectedItinerary
                        if let selectedItinerary = tripPlanManager.pubSelectedItinerary{
                            FareTableManager.shared.pubItineraryCategorisedFares = tripPlanManager.calculateLegCost(itinerary: selectedItinerary)
                        }
                        MapManager.shared.pubIsInTripPlanDetail = true
                        
                        MapManager.shared.pubHideAddressBar = true
                        withAnimation {
                            tripPlanManager.pubShowFullPage = false
                        }
                    }
            }
        }
    }
}

