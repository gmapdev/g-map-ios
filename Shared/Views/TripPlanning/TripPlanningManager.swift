//
//  TripPlanningManager.swift
//

import Foundation
import SwiftUI
import MapKit


class TripPlanToolBarModel: ObservableObject {
    @Published var text: String = "Trips Found"
    @Published var sortImage: String = "sort_shorttolong_icon"
    @Published var sortString: String = "Duration"
}

enum TripItineraryDefaultCost: Double{
    case bikeshareTripCostCents = 200
    case carParkingCostCents = 600
    case drivingCentsPerMile = 44.5
}

class TripPlanningManager: ObservableObject {
    
    @Inject var tripProvider: TripProvider
    @Inject var logServiceProvider: LogServiceProvider
    
    var numberOfReturnRequests = 0
    // MARK: Hold the routing errors returned from the server.
    var routingErrors: [RoutingErrors]?
    var isArriveby: Bool = false
    var isLeaveNow: Bool = true
    var originalGraphQLItineraries: [OTPItinerary] = []
    private var itineraryRenderTimer: Timer?
    private var allModes = FeatureConfig.shared.searchModes
    public var selectedItinerary: OTPItinerary?
    public var graphQLRoutingErrors: [RoutingErrors] = []
    private var formatter: TripPlanningFormatterProtocol = TripPlanningFormatter()
    @ObservedObject var tripSettingsModel = TripSettingsViewModel.shared
    @Published var pubIsShowingTripAlerts = false
    @Published var pubCurrentTripLeg: OTPLeg?
    @Published var pubItineraries: [OTPItinerary] = []
    @Published var pubSelectedItinerary: OTPItinerary?
    @Published var pubPreviousSelectedItinerary: OTPItinerary?                  // to hold previous selected ititnery for live tracking 
    @Published var pubSelectedGroupEntry: GroupEntry?
    @Published var pubCurrentPlanTripParams: RequestTripPlan?
    
    // This contains the processed tripPlan.itineraries
    @Published var pubItems: [GraphQLTripPlanItem] = []
    
    @Published var pubIsLoading: Bool = false
    @Published var pubIsStillLoadingItineraries: Bool = true
    @Published var pubShowFullPage: Bool = true
    @Published var pubShowAccessibilityLegend: Bool = false
    @Published var pubIsAllTransitSelected: Bool = true
    
    @Published var pubSortOption = SortOption.bestOption {
        didSet {
            let sortedItinerary = formatter.sortItineraries(originalGraphQLItineraries, by: pubSortOption, isDescend: self.pubIsDescend)
            self.pubItems = prepareSortedItems(sortedItinerary)
        }
    }
    @Published var pubIsDescend = true
    @Published var pubShowAlert = false
    @Published var isItineraryResult = true
    @Published var pubSelectedTripPlanItem: OTPPlanTrip?
    @Published var pubSaveTripText = "Sign in to save trip"
    /// Pub mode filter collection.
    /// - Parameters:
    ///   - [SearchMode]: Parameter description
    @Published var pubModeFilterCollection: [SearchMode] = [] { // To hold Top items
        didSet {
            pubHasFiltersChanged = hasChanges()
        }
    }
    
    @Published var pubSelectedDate = Date()
    @Published var pubHasFiltersChanged: Bool = false
    @ObservedObject var toolbarModel: TripPlanToolBarModel = TripPlanToolBarModel()
    /// Pub sub mode filter collection.
    /// - Parameters:
    ///   - [SearchMode]: Parameter description
    @Published var pubSubModeFilterCollection: [SearchMode] = []{ // To hold sub items
        didSet {
            pubHasFiltersChanged = hasChanges()
        }
    }
    public var selectedCriterias  = SearchManager.shared.userCriterias{
        didSet {
            pubHasFiltersChanged = hasChanges()
        }
    }
    @Published var pubBannedRoutes: [String: [String]]? = nil
    @Published var pubLastUpdated = Date()
    
    /// Prepare sorted items.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: [GraphQLTripPlanItem]
    private func prepareSortedItems(_ sortedItineraries: [OTPItinerary]) -> [GraphQLTripPlanItem]{
        var itineraryItems = [GraphQLTripPlanItem]()
        for itinerary in sortedItineraries {
            let item = GraphQLTripPlanItem(itinerary: itinerary, isSelected: false, isOtherGroup: false )
            itineraryItems.append(item)
        }
        return itineraryItems
    }
    
    /// Shared.
    /// - Parameters:
    ///   - TripPlanningManager: Parameter description
    public static var shared: TripPlanningManager = {
        let manager = TripPlanningManager()
        return manager
    }()
    
    /// Has changes
    /// - Returns: Bool
    /// Checks if has changes.
    public func hasChanges() -> Bool {
        let isCriteriaChanged = FeatureConfig.shared.defaultCriterias != selectedCriterias
        let configModeCount = FeatureConfig.shared.searchModes.filter({$0.mode == "TRANSIT"}).count
        var configSubmodeCount = 0
        let searchModes = FeatureConfig.shared.searchModes
        if !searchModes.isEmpty {
            configSubmodeCount = FeatureConfig.shared.searchModes[0].selectedSubModes?.count ?? 0
        }
        let isMainFilterChanged = configModeCount != pubModeFilterCollection.count
        let isSubFilterChanged = pubSubModeFilterCollection.count > 0 ? configSubmodeCount != pubSubModeFilterCollection.count : false
        return isCriteriaChanged || isMainFilterChanged || isSubFilterChanged
    }
    
    /// Update sub filter
    /// Updates sub filter.
    public func updateSubFilter() {
        var isSubfilterChanged = false
        var isSearchCriteriaChagned = false
        var isRentalCriteriaChagned = false
        var configSubmodeCount = 0
        let searchModes = FeatureConfig.shared.searchModes
        if !searchModes.isEmpty {
            configSubmodeCount = FeatureConfig.shared.searchModes[0].selectedSubModes?.count ?? 0
        }
        if pubModeFilterCollection.contains(where: {$0.mode == Mode.transit.rawValue}) {
            isSubfilterChanged = pubSubModeFilterCollection.count > 0 ? configSubmodeCount != pubSubModeFilterCollection.count : false
            if tripSettingsModel .isAccessibleRoutingSelected || tripSettingsModel.isAvoidWalkingSelected || PickerListViewModel.shared.isWlakSpeedChanged {
                isSearchCriteriaChagned = true
            } else {
                isSearchCriteriaChagned = false
            }
        } else {
            isSubfilterChanged = false
        }
        
        if pubModeFilterCollection.contains(where: {$0.mode == Mode.rent.rawValue}) {
            isRentalCriteriaChagned = (!tripSettingsModel.isAllowBikeRentalSelected || !tripSettingsModel.isAllowScooterRentalSelected)
        } else {
            isRentalCriteriaChagned = false
        }
        
        tripSettingsModel.isSubFilterValueChanged = isSubfilterChanged || isRentalCriteriaChagned || isSearchCriteriaChagned
    }
    
    /// Reset subfilter
    /// Resets subfilter.
    func resetSubfilter(){
        if FeatureConfig.shared.searchModes.count > 0 {
            self.pubSubModeFilterCollection = FeatureConfig.shared.searchModes[0].selectedSubModes ?? []
        }
        tripSettingsModel.isAvoidWalkingSelected = false
        tripSettingsModel.isAccessibleRoutingSelected = false
        tripSettingsModel.isAllowBikeRentalSelected = true
        tripSettingsModel.isAllowScooterRentalSelected = true
        SearchManager.shared.userCriterias.accessibleRouting = false
        SearchManager.shared.userCriterias.avoidWalking = false
        SearchManager.shared.userCriterias.allowBikeRental = true
        SearchManager.shared.userCriterias.allowScooterRental = true
        PickerListViewModel.shared.isWlakSpeedChanged = false
        
    }
    
    /// Reset top filters
    /// Resets top filters.
    func resetTopFilters(){
        if FeatureConfig.shared.searchModes.count > 0 {
            self.pubModeFilterCollection = FeatureConfig.shared.searchModes.filter({$0.mode == "TRANSIT"})
        }
    }
    
    /// Start fetch trip plan.
    /// - Parameters:
    ///   - selectedModes: Parameter description
    ///   - selectedSubModes: Parameter description
    public func startFetchTripPlan(selectedModes: [SearchMode], selectedSubModes: [SearchMode]) {
        pubIsStillLoadingItineraries = true
        numberOfReturnRequests = 0
        self.graphQLRoutingErrors.removeAll()
        guard let to = SearchManager.shared.to,
              let from = SearchManager.shared.from else {
            return
        }
        
        // clear previous from/to marker for the search address
        MapManager.shared.removePreviewMarkers()
        
        let date = SearchManager.shared.dateSettings
        self.pubItineraries.removeAll()
        self.originalGraphQLItineraries.removeAll()
        withAnimation {
            pubIsLoading = true
        }
        
        var distance: Double = 0.0
        if let fromGeo = from.geometry, let fromCoord = fromGeo.coordinate, let toGeo = to.geometry, let toCoord = toGeo.coordinate {
            distance = checkLocationDistance(from: CLLocation(latitude: fromCoord.latitude, longitude: fromCoord.longitude), to: CLLocation(latitude: toCoord.latitude, longitude: toCoord.longitude))
        }
        
        // Adding Default Walk Mode for GMap
        let newSelectedModes = addWalkMode(selectedModes)
        
        // Extra check for duplicated modes and sub modes
        let filteredSelectedModes = removeDuplicatedModes(from: newSelectedModes)
        let filteredSelectedSubModes = removeDuplicatedModes(from: selectedSubModes)
        
        // if we turn off the route search simulation from 511, then, we use the otp graphql to load the data.
        var sentTransportModeCombinations: [[SelectedMode?]] = [[]]
        if distance < 100 {
            sentTransportModeCombinations.append([SelectedMode(mode: "WALK")])
        }else{
            sentTransportModeCombinations = getModeCombination(selectedModes: filteredSelectedModes, selectedSubModes: filteredSelectedSubModes)
        }
        sentTransportModeCombinations = removeDuplicateArrays(from: sentTransportModeCombinations)
        if sentTransportModeCombinations.count < 1 {
            withAnimation {
                // clear previous from/to marker for the search address
                MapManager.shared.removePreviewMarkers()
                self.graphQLRoutingErrors.append(RoutingErrors(errorCode: RoutingErrorCode.systemError.rawValue, displayText: "No itineraries found", displaySubText: "Can not plan a trip using the seleted modes. Try including transit in your mode selection"))
                pubIsLoading = false
                self.pubIsStillLoadingItineraries = false
            }
        }
        
        let bannedRoutes = getBannedRoutesV2(selectedModes: filteredSelectedModes, selectedSubModes: filteredSelectedSubModes)
        
        let criterias = SearchManager.shared.userCriterias
        
        for sentTransportModeCombination in sentTransportModeCombinations {
            let outputArray = filteredSelectedModes
            let (fromPlaceEncoded, toPlaceEncoded, date, time, wheelchair, bannedRouteObject, arBy, walkReluctanceValue, walkSpeed, requestParams, modeType, stringMode, mobilityProfile) = getRequestParam(from: from, to: to, dateSettings: date, modes: outputArray, modeCombination: sentTransportModeCombination, bannedRoutes: bannedRoutes, criterias: criterias)
            
            tripProvider.retrieveTripPlanUsingGraphQL(fromPlaceEncoded: fromPlaceEncoded, toPlaceEncoded: toPlaceEncoded, date: date, time: time, wheelchair: wheelchair, bannedRouteObject: bannedRouteObject, arBy: arBy, walkReluctanceValue: walkReluctanceValue, walkSpeed: walkSpeed, requestParams: requestParams, modeType: modeType, mobilityProfile: mobilityProfile) { tripPlan, error, serverResponseCode, rawResponse in
                DispatchQueue.main.async { [self] in
                    
                    numberOfReturnRequests += 1
                    if let tripPlan = tripPlan{
                        if let itineraries = tripPlan.itineraries {
                            originalGraphQLItineraries.append(contentsOf: itineraries)
                            renderItineraries()
                            
                            if graphQLRoutingErrors.contains(where: {$0.errorCode == RoutingErrorCode.systemError.rawValue}) {
                                if !originalGraphQLItineraries.isEmpty {
                                    graphQLRoutingErrors = graphQLRoutingErrors.filter({$0.errorCode != RoutingErrorCode.systemError.rawValue})
                                }
                            }
                        }
                    }
                    if error.count > 0 {
                        mapRoutingErrors(errors: error)
                        pubIsLoading = false
                    }
                    
                    if (tripPlan == nil && error.isEmpty) || serverResponseCode == 500{
                        if originalGraphQLItineraries.isEmpty {
                            if numberOfReturnRequests == sentTransportModeCombinations.count {
                                pubIsLoading = false
                            }
                        }
                    }
                    if self.numberOfReturnRequests == sentTransportModeCombinations.count {
                        if !originalGraphQLItineraries.isEmpty {
                            // MARK: Removing NO_TRANSIT_CONNECTION error because WEB has explicitly removed it and confirmed and logged it in ST update tracking excel sheet
                            if graphQLRoutingErrors.contains(where: {$0.errorCode == RoutingErrorCode.noTransitConnection.rawValue}) {
                                graphQLRoutingErrors = graphQLRoutingErrors.filter({$0.errorCode != RoutingErrorCode.noTransitConnection.rawValue})
                            }
                        } else {
                            if graphQLRoutingErrors.isEmpty {
                                graphQLRoutingErrors.append(RoutingErrors(errorCode: RoutingErrorCode.noTransitConnection.rawValue, displayText: "No itineraries found", displaySubText: "No transit connection was found between your origin and destination on the selected day of service, using the vehicle types you selected."))
                            }
                        }
                        pubIsStillLoadingItineraries = false
                    }
                }
            }
        }
    }
    
    /// Remove duplicate arrays.
    /// - Parameters:
    ///   - from: Parameter description
    /// - Returns: [[SelectedMode?]]
    func removeDuplicateArrays(from arrayOfArrays: [[SelectedMode?]]) -> [[SelectedMode?]] {
        var seen = Set<Set<SelectedMode?>>()
        return arrayOfArrays.filter { seen.insert(Set($0)).inserted }
    }

    /// Get request param.
    /// - Parameters:
    ///   - from: Parameter description
    ///   - to: Parameter description
    ///   - dateSettings: Parameter description
    ///   - modes: Parameter description
    ///   - modeCombination: Parameter description
    ///   - bannedRoutes: Parameter description
    ///   - criterias: Parameter description
    /// - Returns: (String, String, String, String, Bool, [String: String]?, Bool, Int, Double, String, [SelectedMode], String, String?)
    func getRequestParam(from: Autocomplete.Feature, to: Autocomplete.Feature, dateSettings: DateSettings, modes: [SearchMode], modeCombination: [SelectedMode?], bannedRoutes: [String], criterias: Criterias) -> (String, String, String, String, Bool, [String: String]?, Bool, Int, Double, String, [SelectedMode], String, String?){
        
        
        let fd = Helper.shared.formatToLocalTimeZoneDate(date: Date(), isTimezone: true)
        let ft = Helper.shared.formatToLocalTimeZoneTime(time: Date(), isTimezone: true)
        
        var time: String = ft
        var date: String = fd
        var arBy = false
        if let departAt = dateSettings.departAt {
            let fd = Helper.shared.formatToLocalTimeZoneDate(date: departAt)
            date = fd
        }else if let arriveBy = dateSettings.arriveBy {
            arBy = true
            let fd = Helper.shared.formatToLocalTimeZoneDate(date: arriveBy)
            date = fd
        }
        
        if let selectedTime = dateSettings.time {
            let ft = Helper.shared.formatToLocalTimeZoneTime(time: selectedTime)
            time = ft
        }
        
        let (fromPlace, fromSubPlace) = Helper.shared.getFormattedPlaceText(feature: from)
        let (toPlace, toSubPlace) = Helper.shared.getFormattedPlaceText(feature: to)
        var mode: [String] = []
        for item in modeCombination {
            if let item = item {
                if let name = item.mode{
                    if let qualifier = item.qualifier {
                        mode.append(name + ":" + qualifier)
                    } else {
                        mode.append(name)
                    }
                }
            }
        }
        var selectedModes: [String] = []
        for item in modes{
            selectedModes.append(item.mode)
        }
        let stringSelectedMode = selectedModes.joined(separator: ",")
        let stringModes = mode.joined(separator: ",")
        let fromLat = from.geometry?.coordinate?.latitude
        let fromLon = from.geometry?.coordinate?.longitude
        let toLat = to.geometry?.coordinate?.latitude
        let toLon = to.geometry?.coordinate?.longitude
        let fromPlaceEncoded = "\(fromPlace)::\(fromLat ?? 0),\(fromLon ?? 0)"
        let toPlaceEncoded = "\(toPlace)::\(toLat ?? 0),\(toLon ?? 0)"
        
        
        var walkReluctanceValue: Int = 15
        if let walkReluctance = criterias.avoidWalking{
            if walkReluctance{
                walkReluctanceValue = 35
            }
        }
        var walkSpeed: Double = 0.0
        
        let _ = FeatureConfig.shared.availableCriterias.walkSpeed.map { item in
            if let value = item[criterias.walkSpeed]{
                walkSpeed = value
            }
        }
        
        let modeType = modeCombination.compactMap({$0})
        
        // map bannedRoutes to pass in GraphQL request
        var bannedRouteObject : [String: String]? = nil
        if !bannedRoutes.isEmpty {
            bannedRouteObject = ["routes" : bannedRoutes.joined(separator: ",")]
        } else {
            bannedRouteObject = [:]
        }
        
        let wheelchair = criterias.accessibleRouting ?? false
        let requestParams = "fromPlace=\(fromPlaceEncoded.percentEncoded())&"
        + "toPlace=\(toPlaceEncoded.percentEncoded())&"
        + "date=\(date)&"
        + "time=\(time.percentEncoded())&"
        + "arriveBy=\(arBy)&"
        + "mode=\(stringSelectedMode.percentEncoded())"
        
        // Special variable for Mobility Profile
        var mobilityMode : String?
        if AppSession.shared.loginInfo != nil {
            if let mobilityProfile = MobileQuestionnairViewModel.shared.selectedMobilityProfile {
                 mobilityMode = mobilityProfile.mobilityMode ?? "None"
            }
            if !(TravelCompanionsViewModel.shared.pubDependents.isEmpty) && !(TripSettingsViewModel.shared.pubSelectedMobilityProfile.lowercased() == "myself"){
                mobilityMode = TravelCompanionsViewModel.shared.setMobilityFor(selectedUser: TripSettingsViewModel.shared.pubSelectedMobilityProfile)
            }
        }
        
        return (fromPlaceEncoded, toPlaceEncoded, date, time, wheelchair, bannedRouteObject, arBy, walkReluctanceValue, walkSpeed, requestParams, modeType, stringModes, mobilityMode)
    }
    
    /// Filter itineraries.
    /// - Parameters:
    ///   - itineraries: Parameter description
    ///   - selectedModes: Parameter description
    ///   - selectedSubModes: Parameter description
    /// - Returns: [OTPItinerary]
    func filterItineraries(itineraries: [OTPItinerary], selectedModes: [SearchMode], selectedSubModes: [SearchMode]) -> [OTPItinerary] {
        var filteredItineraries: [OTPItinerary] = []
        var combinedModes: [SearchMode] = []
        combinedModes.append(contentsOf: selectedModes)
        combinedModes.append(contentsOf: selectedSubModes)
        
        combinedModes = Helper.shared.removeTDuplicates(from: combinedModes)
        
        for item in itineraries {
            if let legs = item.legs {
                for leg in legs {
                    if leg.mode == Mode.bicycle.rawValue {
                        if let rentedBike = leg.rentedBike {
                            if rentedBike {
                                if combinedModes.contains(where: { mode in
                                    mode.mode == Mode.bicycle_rent.rawValue
                                }) {
                                    filteredItineraries.append(item)
                                }
                            } else {
                                if combinedModes.contains(where: { mode in
                                    mode.mode == Mode.bicycle.rawValue
                                }) {
                                    filteredItineraries.append(item)
                                }
                            }
                        } else {
                            if combinedModes.contains(where: { mode in
                                mode.mode == Mode.bicycle.rawValue
                            }) {
                                filteredItineraries.append(item)
                            }
                        }
                    } else if leg.mode == Mode.scooter.rawValue {
                        if combinedModes.contains(where: { mode in
                            mode.mode == Mode.scooter_rent.rawValue
                        }) {
                            filteredItineraries.append(item)
                        }
                    } else {
                        if combinedModes.contains(where: { mode in
                            mode.mode == leg.mode
                        }) {
                            filteredItineraries.append(item)
                        }
                    }
                }
            }
        }
        return filteredItineraries
    }
    
    /// Remove duplicated modes.
    /// - Parameters:
    ///   - from: Parameter description
    /// - Returns: [SearchMode]
    func removeDuplicatedModes(from array: [SearchMode]) -> [SearchMode] {
        var seen = Set<SearchMode>()
        return array.filter { mode in
            if seen.contains(mode) {
                return false
            } else {
                seen.insert(mode)
                return true
            }
        }
    }
    
    /// Add walk mode.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: [SearchMode]
    func addWalkMode(_ modes : [SearchMode]) -> [SearchMode]{
        var newModes = modes
        if !(modes.contains(where: {$0.mode == "WALK"})){
            if let walkMode = FeatureConfig.shared.allModesList.first(where: {$0.mode == "WALK"}){
                newModes.append(walkMode)
            }
        }
        return newModes
    }
    
    /// Get banned routes.
    /// - Parameters:
    ///   - selectedModes: Parameter description
    ///   - selectedSubModes: Parameter description
    /// - Returns: [String]
    func getBannedRoutes(selectedModes: [SearchMode], selectedSubModes: [SearchMode]) -> [String] {
        guard selectedModes.contains(where: { $0.mode == Mode.transit.rawValue }) else {
            return []
        }
        let allSubModes = TripTransitFiltersViewModel.shared.subitems
        var bannedSubModes = allSubModes.filter { !selectedSubModes.contains($0) }
        bannedSubModes.removeAll(where: {$0.mode == Mode.bus.rawValue})
        bannedSubModes.removeAll(where: {$0.mode == Mode.rail.rawValue})
        bannedSubModes.removeAll(where: {$0.mode == Mode.monorail.rawValue})
        if bannedSubModes.contains(where: { $0.mode == Mode.tram.rawValue }) {
            bannedSubModes.removeAll { $0.mode == Mode.tram.rawValue }
            bannedSubModes.append(SearchMode(mode: "LINK", label: "", mode_image: "", marker_image: "", line_color: "", color: ""))
        }
        let routes = RouteViewerModel.shared.pubRouteItems
        let bannedModesSet = Set(bannedSubModes.map { $0.mode })
        let bannedRoutes = RouteViewerModel.shared.pubRouteItems
            .filter { bannedModesSet.contains($0.route.mode?.rawValue ?? "") }
            .map { $0.route.id }
        return bannedRoutes
    }
    
    /// Get banned routes v2.
    /// - Parameters:
    ///   - selectedModes: Parameter description
    ///   - selectedSubModes: Parameter description
    /// - Returns: [String]
    func getBannedRoutesV2(selectedModes: [SearchMode], selectedSubModes: [SearchMode]) -> [String] {
        guard selectedModes.contains(where: { $0.mode == Mode.transit.rawValue }) else {
            return []
        }
        let allSubModes = TripTransitFiltersViewModel.shared.subitems
        var bannedSubModes = allSubModes.filter { !selectedSubModes.contains($0) }
        bannedSubModes.removeAll(where: {$0.mode == Mode.bus.rawValue})
        bannedSubModes.removeAll(where: {$0.mode == Mode.rail.rawValue})
        bannedSubModes.removeAll(where: {$0.mode == Mode.monorail.rawValue})
        if bannedSubModes.contains(where: { $0.mode == Mode.tram.rawValue }) {
            bannedSubModes.removeAll { $0.mode == Mode.tram.rawValue }
            bannedSubModes.append(SearchMode(mode: Mode.linkLightRail.rawValue, label: "", mode_image: "", marker_image: "", line_color: "", color: ""))
        }
        var returnIds:[String] = []
        if let bannedRoutes = self.pubBannedRoutes {
            for item in bannedSubModes {
                let filteredRouteId = bannedRoutes.filter({$0.key == item.mode}).map({$0.value})
                if bannedRoutes.contains(where: {$0.key == item.mode}) {
                    if let bannedIds = bannedRoutes[item.mode] {
                        returnIds.append(contentsOf: bannedIds)
                    }
                }
            }
        }
        return returnIds
    }
    
    /// Check location distance.
    /// - Parameters:
    ///   - from: Parameter description
    ///   - to: Parameter description
    /// - Returns: Double
    func checkLocationDistance(from: CLLocation, to: CLLocation) -> Double{
        let distance = from.distance(from: to)
        return distance
    }
    
    /// Get mode combination.
    /// - Parameters:
    ///   - selectedModes: Parameter description
    ///   - selectedSubModes: Parameter description
    /// - Returns: [[SelectedMode?]]
    func getModeCombination(selectedModes: [SearchMode], selectedSubModes: [SearchMode]) -> [[SelectedMode?]]{
        let modeCombinations = ModeManager.shared.modeCombinations
        /// String selected modes.
        /// - Parameters:
        ///   - [String]: Parameter description
        var stringSelectedModes: [String] = selectedModes.map { $0.mode}
        /// String selected sub modes.
        /// - Parameters:
        ///   - [String]: Parameter description
        var stringSelectedSubModes: [String] = selectedSubModes.map({$0.mode})
        if stringSelectedSubModes.contains(where: {$0 == Mode.water_taxi.rawValue}) {
            stringSelectedSubModes.removeAll {$0 == Mode.water_taxi.rawValue}
            stringSelectedSubModes.append(Mode.ferry.rawValue)
        }
        
        if stringSelectedSubModes.contains(where: {$0 == Mode.streetcar.rawValue}) {
            stringSelectedSubModes.removeAll {$0 == Mode.streetcar.rawValue}
            stringSelectedSubModes.append(Mode.tram.rawValue)
        }
        var sentTransportModeCombinations: [[SelectedMode?]] = []
        if let modeCombinations = modeCombinations {
            for i in 0..<modeCombinations.count {
                let combination = modeCombinations[i].selectedModes
                let subCombination : [String] = modeCombinations[i].selectedSubModes
                let modeResult = arrayIncludes(shouldInclude: combination, setToCompare: mapArray(array: stringSelectedModes))
                let subModeResult = arrayIncludes(shouldInclude: subCombination, setToCompare: mapArray(array: stringSelectedSubModes))
                
                if modeResult && subModeResult {
                    if let sentModeCombinations = modeCombinations[i].sentModeCombinations {
                        for item in sentModeCombinations {
                            let returnModes = mapFilterModes(modes: item)
                            sentTransportModeCombinations.append(returnModes)
                        }
                    }
                }
            }
        }
        
        return sentTransportModeCombinations
    }
    
    /// Map array.
    /// - Parameters:
    ///   - array: Parameter description
    /// - Returns: [String]
    func mapArray(array: [String]) -> [String] {
        return array.map { $0 == "STREETCAR" ? "TRAM" : $0 }
    }
    
    /// Array includes.
    /// - Parameters:
    ///   - shouldInclude: Parameter description
    ///   - setToCompare: Parameter description
    /// - Returns: Bool
    func arrayIncludes(shouldInclude: [String], setToCompare: [String]) -> Bool {
        let shouldIncludeSet = NSCountedSet(array: shouldInclude)
        let setToCompareSet = NSCountedSet(array: setToCompare)
        
        if shouldIncludeSet.count != setToCompareSet.count {
            return false
        }
        
        for inc in shouldIncludeSet {
            if shouldIncludeSet.count(for: inc) != setToCompareSet.count(for: inc) {
                return false
            }
        }
        return true
    }
    
    //MARK: - get search mode type from String mode.
    /// Retrieves search modefrom name.
    /// - Parameters:
    ///   - mode: String
    /// - Returns: SearchMode
    func getSearchModefromName(mode: String) -> SearchMode {
        let allModesList = FeatureConfig.shared.allModesList
        
        if let searchMode = allModesList.first(where: { $0.mode == mode}){
            return searchMode
        } else {
            return allModesList.count > 0 ? allModesList.first! : SearchMode(mode: "BUS", label: "Bus", mode_image: "ic_bus", marker_image: "ic_marker_bus", line_color: "#7da8ef", color: "#e05522")
        }
    }
    
    /// Map filter modes.
    /// - Parameters:
    ///   - modes: Parameter description
    /// - Returns: [SelectedMode?]
    func mapFilterModes(modes: SentModeCombinations) -> [SelectedMode?] {
        
        var transportMode: SelectedMode?
        let transportModes = modes.modes?.map { mMode in
            if let mStringMode = mMode.mode {
                if let mQualifier = mMode.qualifier{
                    transportMode = SelectedMode(mode: mStringMode, qualifier: mQualifier)
                }else{
                    transportMode = SelectedMode(mode: mStringMode)
                }
            }
            return transportMode
        }
        return transportModes ?? []
    }
    
    /// Render itineraries
    /// Renders itineraries.
    public func renderItineraries(){
        if let timer = self.itineraryRenderTimer {
            timer.invalidate()
            self.itineraryRenderTimer = nil
        }
        self.itineraryRenderTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { timer in
            self.startRenderItineraries()
        })
    }
    
    /// Start render itineraries
    /// Starts render itineraries.
    public func startRenderItineraries(){
        
        var uniqueItineraries = [OTPItinerary]()
        
        for i in 0..<self.originalGraphQLItineraries.count {
            var find = false
            for j in 0..<uniqueItineraries.count {
                if uniqueItineraries[j] == originalGraphQLItineraries[i] {
                    find = true
                    break
                }
            }
            if !find {
                let itinerary = originalGraphQLItineraries[i]
                uniqueItineraries.append(itinerary)
            }
        }
        toolbarModel.text = DataFormatter.convert(pubItineraries.count)
        
        
        DispatchQueue.main.async {
            self.pubItineraries = uniqueItineraries
            self.originalGraphQLItineraries = uniqueItineraries
            withAnimation {
                self.pubIsLoading = false
            }
            if self.graphQLRoutingErrors.count > 0 {
                self.pubShowAlert = true
            }
        }
    }
    
    /// Cancel all itineraries requests
    /// Cancels all itineraries requests.
    public func cancelAllItinerariesRequests(){
        self.allModes.removeAll()
        self.originalGraphQLItineraries.removeAll()
    }
    
    /// Get route color.
    /// - Parameters:
    ///   - leg: Parameter description
    /// - Returns: String
    func getRouteColor(leg: OTPLeg?) -> String {
        if let leg = leg{
            if let route = leg.route, let color = route.color{
                return color
            }else{
                if leg.searchMode?.mode == "BICYCLE"{
                    return "FF0103"
                }else if leg.searchMode?.mode == "WALK"{
                    return "87CEFA"
                }
            }
            return "000000"
        }
        return "000000"
    }
    
    /// Get route name.
    /// - Parameters:
    ///   - leg: Parameter description
    /// - Returns: String
    func getRouteName(leg: OTPLeg?) -> String {
        var routeName = ""
        if let leg = leg, let route = leg.route{
            if let shortName = route.shortName, !shortName.isEmpty {
                routeName = shortName
            } else if let longName = route.longName, !longName.isEmpty {
                routeName = longName
            } else {
                routeName = ""
            }
        }
        return routeName
    }
    
    /// Get route short name.
    /// - Parameters:
    ///   - leg: Parameter description
    /// - Returns: String
    func getRouteShortName(leg: OTPLeg?) -> String {
        if let leg = leg, let route = leg.route, let shortName = route.shortName{
            return shortName
        }
        return ""
    }
    
    /// Get route long name.
    /// - Parameters:
    ///   - leg: Parameter description
    /// - Returns: String
    func getRouteLongName(leg: OTPLeg?) -> String {
        if let leg = leg, let route = leg.route, let longName = route.longName{
            return longName
        }
        return ""
    }
    
    /// Time text.
    /// - Parameters:
    ///   - for: Parameter description
    /// - Returns: (String, Double)
    func timeText(for timeInterval: String) -> (String, Double) {
        var timeString = timeInterval.convertToTimeInterval().format()
        // return time in seconds
        if timeString.contains("sec"){
            return (timeString, timeInterval.convertToTimeInterval())
        }
        else{
            timeString = timeString.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: " min", with: "")
            
            //return time in hr, min format
            if let minutes = Int(timeString), minutes >= 60 {
                let hours: Int = minutes / 60
                let leftMinutes: Int = minutes % 60
                return ("%1 hr, %2 min".localized(hours, leftMinutes), timeInterval.convertToTimeInterval())
            }
            //return time in minutes
            return ("%1 min".localized(timeString), timeInterval.convertToTimeInterval())
        }
    }
    
    /// Create show time.
    /// - Parameters:
    ///   - itinerary: Parameter description
    /// - Returns: String
    func createShowTime(itinerary : OTPItinerary) -> String {
        var returnString = ""
        if let startTime = itinerary.startTime, let endTime = itinerary.endTime{
            let stringStartTime = self.milliSecondsTimeToLocalZone(time: String(startTime))
            let stringEndTime = self.milliSecondsTimeToLocalZone(time: String(endTime))
            returnString =  stringStartTime + " - " + stringEndTime
        }
        return returnString
    }
    
    /// Create show timefor edit trip.
    /// - Parameters:
    ///   - itinerary: Parameter description
    /// - Returns: String
    func createShowTimeforEditTrip(itinerary : OTPItinerary) -> String {
        var returnString = ""
        if let startTime = itinerary.startTime, let endTime = itinerary.endTime{
            let stringStartTime = self.milliSecondsTime(time: String(startTime))
            let stringEndTime = self.milliSecondsTime(time: String(endTime))
            returnString =  stringStartTime + " - " + stringEndTime
        }
        return returnString
    }
    
    /// Get walking time.
    /// - Parameters:
    ///   - itinerary: Parameter description
    /// - Returns: String
    func getWalkingTime(itinerary: OTPItinerary) -> String {
        var time: TimeInterval = 0
        if let legs = itinerary.legs {
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
            walkingTime = "\(hours) " + (hours > 1 ? "hours".localized() : "hour".localized())
        }
        if minutes > 0 {
            
            walkingTime += (hours > 0 ? " " : "") + "\(minutes) " + (minutes > 1 ? "minutes".localized() : "minutes".localized())
        }else {
            walkingTime += (hours > 0 ? " " : "") + "0 " + "minutes".localized()
        }
        
        return walkingTime
    }
    
    /// Get cycling time.
    /// - Parameters:
    ///   - itinerary: Parameter description
    /// - Returns: String
    func getCyclingTime(itinerary: OTPItinerary) -> String {
        var time: TimeInterval = 0
        if let legs = itinerary.legs {
            for leg in legs{
                if (leg.searchMode?.mode ?? "") == "BICYCLE"{
                    time += Double(leg.duration ?? 0)
                }
            }
        }
        time = floor(time/60)
        
        let hours = Int(time)/60
        let minutes = Int(time)%60
        var walkingTime = ""
        if hours > 0 {
            walkingTime = "\(hours) " + (hours > 1 ? "hours".localized() : "hour".localized())
        }
        if minutes > 0 {
            walkingTime += (hours > 0 ? " " : "") + "\(minutes) " + (minutes > 1 ? "minutes".localized() : "minutes".localized())
        }else {
            walkingTime += (hours > 0 ? " " : "") + "0 " + "minutes".localized()
        }
        
        return walkingTime
    }
    
    /// Milli seconds time to local zone.
    /// - Parameters:
    ///   - time: Parameter description
    ///   - delay: Parameter description
    /// - Returns: String
    func milliSecondsTimeToLocalZone(time: String, delay: Double = 0) -> String {
        let convertedTime = time.convertToTimeInterval()
        
        let date = Date(timeIntervalSince1970: convertedTime/1000)
        let newDate = date.addingTimeInterval(-delay)
        let dateFormatter = DateFormatter()
        let language = SettingsManager.shared.appLanguage
        dateFormatter.locale = Locale(identifier: language.languageCode())
        dateFormatter.timeZone = EnvironmentManager.shared.currentTimezone
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.string(from: newDate)
    }
    
    /// Milli seconds time.
    /// - Parameters:
    ///   - time: Parameter description
    ///   - delay: Parameter description
    /// - Returns: String
    func milliSecondsTime(time: String, delay: Double = 0) -> String {
        let convertedTime = time.convertToTimeInterval()
        
        let date = Date(timeIntervalSince1970: convertedTime/1000)
        let newDate = date.addingTimeInterval(-delay)
        let dateFormatter = DateFormatter()
        let language = SettingsManager.shared.appLanguage
        dateFormatter.locale = Locale(identifier: language.languageCode())
        dateFormatter.timeZone = EnvironmentManager.shared.currentTimezone
        dateFormatter.dateFormat = "h:mm a"
        return dateFormatter.string(from: newDate)
    }
    
    /// Milli seconds date.
    /// - Parameters:
    ///   - date: Parameter description
    ///   - delay: Parameter description
    /// - Returns: String
    func milliSecondsDate(date: String, delay: Double = 0) -> String {
        let convertedDate = date.convertToTimeInterval()
        let date = Date(timeIntervalSince1970: convertedDate/1000)
        let dateFormatter = DateFormatter()
        let language = SettingsManager.shared.appLanguage
        dateFormatter.locale = Locale(identifier: language.languageCode())
        dateFormatter.timeZone = EnvironmentManager.shared.currentTimezone
        dateFormatter.dateFormat = "MMM dd, yyyy"
        return dateFormatter.string(from: date)
    }
    
    /// Time interval to date.
    /// - Parameters:
    ///   - timeInterval: Parameter description
    ///   - delay: Parameter description
    /// - Returns: String
    func timeIntervalToDate(timeInterval: Int, delay: Double = 0) -> String {
        let convertedDate = TimeInterval(timeInterval)
        let date = Date(timeIntervalSince1970: convertedDate)
        let dateFormatter = DateFormatter()
        let language = SettingsManager.shared.appLanguage
        dateFormatter.locale = Locale(identifier: language.languageCode())
        dateFormatter.timeZone = EnvironmentManager.shared.currentTimezone
        dateFormatter.dateFormat = "MMMM dd, yyyy"
        return dateFormatter.string(from: date)
    }
    
    /// Did select item.
    /// - Parameters:
    ///   - _: Parameter description
    /// Handles when did select item.
    func didSelectItem(_ item: OTPItinerary?) {
        
        self.pubItineraries = self.pubItineraries.map({
            var updatedItem = $0
            if $0.id == item?.id {
                updatedItem.isSelected = true
            }else{
                updatedItem.isSelected = false
            }
            return updatedItem
        })
        
        if let itineraryItem = item {
            
            self.selectedItinerary = itineraryItem
            
            var origin:CLLocationCoordinate2D?
            var destination:CLLocationCoordinate2D?
            var segements = [GraphQLRouteSegment]()
            var specialRoutePoint = [GraphQLRouteSpecialPoint]()
            if let legs = itineraryItem.legs {
                for leg in legs {
                    var coordinates = [CLLocationCoordinate2D]()
                    let from = CLLocationCoordinate2DMake(leg.from?.lat ?? 0.0, leg.from?.lon ?? 0.0)
                    let to = CLLocationCoordinate2DMake(leg.to?.lat ?? 0.0, leg.to?.lon ?? 0.0)
                    
                    if let routePath = leg.legGeometry?.points {
                        if routePath != "" {
                            let polyline = Polyline(encodedPolyline: routePath)
                            if let decodedCoordinates = polyline.coordinates {
                                coordinates.append(contentsOf: decodedCoordinates)
                            }
                        }
                    }
                    
                    if origin == nil { origin = from }
                    destination = to
                    
                    var routeColor = UIColor.lightGray
                    if let colorCode = leg.route?.color, let color = UIColor(hex: "#\(colorCode)FF"){
                        routeColor = color
                    }else{
                        routeColor = UIColor(Color(hex: getRouteColor(leg: leg)))
                    }
                    if leg.searchMode?.mode == Mode.bus.rawValue || leg.searchMode?.mode == Mode.rail.rawValue || leg.searchMode?.mode == Mode.subway.rawValue || leg.searchMode?.mode == Mode.tram.rawValue || leg.searchMode?.mode == Mode.transit.rawValue {
                        let routeName = getRouteShortName(leg: leg)
                        if coordinates.count > 2 && routeName.count > 0 {
                            let index = (Int)(coordinates.count/2)
                            let middleCoorindate = coordinates[index]
                            let specialPoint = GraphQLRouteSpecialPoint(coordinate: middleCoorindate, color: routeColor, info: routeName)
                            specialRoutePoint.append(specialPoint)
                        }
                    }
                    if let mode = leg.searchMode?.mode {
                        let routeSegment = GraphQLRouteSegment(routeType: mode, routeColor: routeColor, coorindates: coordinates)
                        if routeSegment.coorindates.count>0{
                            segements.append(routeSegment)
                        }
                    }
                }
            }
            
            if let origin = origin, let destination = destination {
                let plotItem = GraphQLPlanTripPlotItems(segments: segements, origin: origin, destination: destination, specialRoutePoint: specialRoutePoint)
                MapManager.shared.graphQLPlanTripPlotItems = plotItem
                if let planTripPlot = MapManager.shared.graphQLPlanTripPlotItems{
                    MapManager.shared.graphQLPlotRoute(segments: planTripPlot.segments,
                                                       origin: planTripPlot.origin,
                                                       destination: planTripPlot.destination,
                                                       specialRoutePoint: planTripPlot.specialRoutePoint)
                    DispatchQueue.main.async {
                        let viewArea = ViewArea(topRight: CGPoint(x:UIScreen.main.bounds.width,y:0), bottomLeft: CGPoint(x:0, y: Helper.shared.getDeafultViewHeight(heightPosition: .bottom)))
                        let edgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 20)
                        MapManager.shared.setCenterArea(viewArea: viewArea, mapViewHeight: Helper.shared.getDefaultMapViewHeight(), mapViewWidth: UIScreen.main.bounds.width,edgeInset: edgeInsets)
                    }
                    
                }
            }
        }
        else{
            self.selectedItinerary = nil
        }
    }
    

    /// Get pure walk time.
    /// - Parameters:
    ///   - itinerary: Parameter description
    /// - Returns: Double
    func getPureWalkTime(itinerary: OTPItinerary) -> Double{
        var walkTime: TimeInterval = 0
        if let legs = itinerary.legs {
            for leg in legs{
                if (leg.searchMode?.mode ?? "") == "WALK"{
                    walkTime += Double(leg.duration ?? 0)
                }
            }
        }
        return walkTime
    }
    
    
    //MARK: just to get total Walking time on each Itinerary item.
    // return total seconds in the minutes position.
    /// Retrieves total walk time.
    /// - Parameters:
    ///   - itinerary: OTPItinerary
    /// - Returns: (String?, Double)
    func getTotalWalkTime(itinerary: OTPItinerary) -> (String?, Double){
        var walkTime: TimeInterval = 0
        var bicycleTime: TimeInterval = 0
        var totalTime: TimeInterval = 0
        if let legs = itinerary.legs {
            for leg in legs{
                if (leg.searchMode?.mode ?? "") == "WALK"{
                    walkTime += Double(leg.duration ?? 0)
                }
            }
        }
        walkTime = floor(walkTime/60)
        
        if let legs = itinerary.legs {
            for leg in legs{
                if (leg.searchMode?.mode ?? "") == "BICYCLE"{
                    bicycleTime += Double(leg.duration ?? 0)
                }
            }
        }
        bicycleTime = floor(bicycleTime/60)
        totalTime = walkTime + bicycleTime
        if totalTime > 60 {
            let hours = Int(totalTime)/60
            let minutes = Int(totalTime)%60
            var returnTime = ""
            if hours > 0 {
                returnTime = "\(hours) " + (hours > 1 ? "hours" : "hour")
            }
            if minutes > 0 {
                returnTime += (hours > 0 ? " " : "") + "\(minutes) " + (minutes > 1 ? "minutes".localized() : "minutes".localized())
            }else {
                returnTime += (hours > 0 ? " " : "") + "0 " + "minute".localized()
            }
            
            return (returnTime, totalTime)
        } else {
            return (String(format: "%.0f", floor(totalTime)) + (totalTime > 1 ? " " + "minutes".localized() : " " + "minutes".localized()), totalTime)
        }
    }
    
    
    
    // MARK: - Fare Calculation logic to get the Total fare for Itinerary
      /// This is rewritten logic to exect match with WEB, tested and suitable for GMAP
      ///  Note : This logic only use the OTPFareProduct Strucure and removing the FareProduct Structure from logic
      
      /// Get itinerary cost.
      /// - Parameters:
      ///   - itinerary: Parameter description
      ///   - mediumId: Parameter description
      ///   - riderCategoryId: Parameter description
      /// - Returns: (formatted: String, amount: Double)
      func getItineraryCost(itinerary: OTPItinerary, mediumId: String? = nil, riderCategoryId: String? = nil) -> (formatted: String, amount: Double) {
          guard let legs = itinerary.legs else {
              return ("", 0.0)
          }
          var seenProductUseIds = Set<String>()
          var totalAmount: Double = 0.0
          for (index, leg) in legs.enumerated() {
              guard let cost = getLegFare(leg: leg, mediumId: mediumId, riderCategoryId: riderCategoryId) else {
                  continue
              }
              if let id = cost.productUseId {
                  if seenProductUseIds.contains(id) {
                      continue
                  }
                  seenProductUseIds.insert(id)
              }
              if let amount = cost.price?.amount {
                  totalAmount += amount
              }
          }

          if totalAmount == 0 {
              return ("", 0.0)
          } else {
              let formatted = String(format: "$%.2f", totalAmount)
              return (formatted, totalAmount)
          }
      }

      // MARK: - Leg-Level Fare Logic
      /// Retrieves leg fare.
      /// - Parameters:
      ///   - leg: OTPLeg
      ///   - mediumId: String?
      ///   - riderCategoryId: String?
      /// - Returns: (price: OTPPrice?, transferAmount: OTPPrice?, productUseId: String?)?
      private func getLegFare(leg: OTPLeg, mediumId: String?, riderCategoryId: String?) -> (price: OTPPrice?, transferAmount: OTPPrice?, productUseId: String?)? {
          guard let fareProducts = leg.fareProducts else {
              return nil
          }

          let matchingProducts = fareProducts.filter { fareProduct in
              guard let product = fareProduct.product else {
                  return false
              }

              let productMediumId = product.medium?.id?.rawValue
              let productRiderCategoryId = product.riderCategory?.id?.rawValue
              let mediumMatches = (mediumId == nil && productMediumId == nil) || (mediumId != nil && productMediumId == mediumId)
              let categoryMatches = (riderCategoryId == nil && productRiderCategoryId == nil) || (riderCategoryId != nil && productRiderCategoryId == riderCategoryId)

              return mediumMatches && categoryMatches
          }
          let rideCostProduct = matchingProducts.first(where: {
              $0.product?.name == .rideCost || $0.product?.name == .regular
          })

          let transferProduct = matchingProducts.first(where: {
              $0.product?.name == .transfer
          })

          return (
              price: rideCostProduct?.product?.price,
              transferAmount: transferProduct?.product?.price,
              productUseId: rideCostProduct?.id
          )
      }
      
    
    //MARK: to get Structured return for showing in the ItinerayView with whole Table data
    /// Calculates leg cost.
    /// - Parameters:
    ///   - itinerary: OTPItinerary
    /// - Returns: [String : [FareProduct]]
    func calculateLegCost(itinerary: OTPItinerary) -> [String : [FareProduct]]{
        var TotalFaresTable: [String : [FareProduct]] = [:]
        let fareProduct = prepareFareProduct(itinerary: itinerary)
        
        var adultArray: [FareProduct] = []
        var youthArray: [FareProduct] = []
        var seniorArray: [FareProduct] = []
        for product in fareProduct{
            let category = product.product.riderCategory.name
            if category == .adult || category == .special{       // added Special for adult beacuse it giving ORCA LIFT values for adult.
                adultArray.append(product)                       /// we are not receiving different type as ORCA LIFT insted we have special category where medium is ORCA for reference check on web.
            }else if category == .youth{
                youthArray.append(product)
            }else if category == .senior{
                seniorArray.append(product)
            }
        }
        TotalFaresTable[RiderCategoryType.adult.rawValue] = adultArray
        TotalFaresTable[RiderCategoryType.youth.rawValue] = youthArray
        TotalFaresTable[RiderCategoryType.senior.rawValue] = seniorArray
        return TotalFaresTable
    }
    
    /// Prepare fare product.
    /// - Parameters:
    ///   - itinerary: Parameter description
    /// - Returns: [FareProduct]
    func prepareFareProduct(itinerary: OTPItinerary) -> [FareProduct]{
        guard let legs = itinerary.legs else {
            return []
        }
        
        var fareResponseInfo: [FareProduct] = []
        var removableTransitLegs: [String] = []
        var skippedTransitLegs: [String] = []
        
        for leg in legs.compactMap({ $0 }) {
            if let fareProducts = leg.fareProducts {
                for fareProduct in fareProducts.compactMap({ $0 }){
                    if let fareProductId = fareProduct.id,
                       let product = fareProduct.product,
                       let productName = product.name{
                        if productName == .rideCost || productName == .regular || productName == .transfer{
                            let id = product.id ?? .unknown
                            
                            if let productMedium = product.medium,
                               let productRiderCategory = product.riderCategory {
                                
                                let modeName = leg.route?.shortName ?? leg.route?.longName ?? "N/A"
                                var name = product.name ?? .unknown
                                var medium = Medium(id: (productMedium.id ?? .unknown).rawValue,
                                                    name: getMedium(name: (productMedium.name ?? .unknown).rawValue))
                                let category = RiderCategory(id: (productRiderCategory.id ?? .unknown).rawValue, name: getRiderCategory(name: (productRiderCategory.name ?? .unknown).rawValue))
                                
                                let price = Price(amount: String(product.price?.amount ?? 0),
                                                  currency: Currency(code: (product.price?.currency?.code ?? .unknown).rawValue,
                                                                     digits: (product.price?.currency?.digits ?? 2)))
                                if medium.name == .orca && category.name == .special{
                                    medium = Medium(id: (productMedium.id ?? .unknown).rawValue, name: .orca_lift)
                                }
                                let newFareProduct = FareProduct(id: fareProductId, product: Product(id: id.rawValue, medium: medium, name: name.rawValue, riderCategory: category, price: price, modeName: modeName))
                                fareResponseInfo.append(newFareProduct)
                                
                                if !removableTransitLegs.contains(modeName){
                                    removableTransitLegs.append(modeName)
                                }
                            }
                            else{
                                if !skippedTransitLegs.contains((leg.route?.shortName ?? leg.route?.longName) ?? ""){
                                    skippedTransitLegs.append((leg.route?.shortName ?? leg.route?.longName) ?? "")
                                }
                            }
                        }
                    }
                }
            }
        }
        
        skippedTransitLegs.removeAll(where:{removableTransitLegs.contains($0)})
        for modeName in skippedTransitLegs {
            let mediums: [FareMedium] = [.cash, .orca]
            let mediumsforAdult: [FareMedium] = mediums + [.orca_lift]
            
            for category in [RiderCategoryType.adult, RiderCategoryType.youth, RiderCategoryType.senior] {
                let fareMediums = (category == .adult) ? mediumsforAdult : mediums
                for medium in fareMediums {
                    let product = FareProduct(
                        id: "",
                        product: Product(
                            id: "",
                            medium: Medium(id: "", name: medium),
                            name: "",
                            riderCategory: RiderCategory(id: "", name: category),
                            price: Price(amount: "-", currency: Currency(code: "", digits: 0)),
                            modeName: modeName
                        )
                    )
                    fareResponseInfo.append(product)
                }
            }
        }
        return fareResponseInfo
    }
    
    /// Get rider category.
    /// - Parameters:
    ///   - name: Parameter description
    /// - Returns: RiderCategoryType
    func getRiderCategory(name: String) -> RiderCategoryType {
        return RiderCategoryType(rawValue: name) ?? .unknown
    }
    
    /// Get medium.
    /// - Parameters:
    ///   - name: Parameter description
    /// - Returns: FareMedium
    func getMedium(name: String) -> FareMedium {
        return FareMedium(rawValue: name) ?? .unknown
    }
    
    //MARK: Stop related functions
    
    /// Stop display identifier.
    /// - Parameters:
    ///   - leg: Parameter description
    /// - Returns: String
    func stopDisplayIdentifier(leg: OTPLeg?) -> String {
        var stopId = ""
        if let leg = leg {
            if let from = leg.from, let stop = from.stop, let code = stop.code {
                return code
            }
            if let from = leg.from, let stop = from.stop {
                stopId = stop.gtfsID ?? ""
                if let sid = stop.gtfsID {
                    stopId = sid.components(separatedBy: ":").last ?? ""
                }
                if stopId.isEmpty {
                    if let sid = stop.gtfsID {
                        stopId = sid.components(separatedBy: "::").last ?? ""
                    }
                }
            }
        }
        return stopId
    }
    
    //MARK: Map routing error codes
    /// Map routing errors.
    /// - Parameters:
    ///   - errors: [RoutingErrorResponse]
    func mapRoutingErrors(errors: [RoutingErrorResponse]) {
        let uniqueErrors = Set(errors)
        var errorCode = ""
        var errorTitleMessage = ""
        var errorDescriptionMessage = ""
        
        if let maxError = uniqueErrors.max(by: { $0.code.count < $1.code.count }) {
            errorCode = maxError.code
            
            if let routingError = self.routingErrors?.first(where: { $0.errorCode == maxError.code }) {
                if routingError.displaySubText.contains("$0 $1") {
                    let fromText = uniqueErrors.contains(where: { $0.inputField == "FROM" }) ? "Origin" : ""
                    let toText = uniqueErrors.contains(where: { $0.inputField == "TO" }) ? "Destination" : ""
                    let locationsText = (fromText.isEmpty || toText.isEmpty) ? "location is" : "locations are"
                    
                    errorTitleMessage = routingError.displayText
                    errorDescriptionMessage = routingError.displaySubText
                        .replacingOccurrences(of: "$0", with: !fromText.isEmpty && !toText.isEmpty ? "\(fromText) and \(toText)" : "\(fromText)\(toText)")
                        .replacingOccurrences(of: "$1", with: locationsText)
                } else {
                    errorTitleMessage = routingError.displayText
                    errorDescriptionMessage = routingError.displaySubText
                }
            } else {
                errorCode = ""
                errorTitleMessage = ""
                errorDescriptionMessage = ""
            }
        } else {
            errorCode = ""
            errorTitleMessage = ""
            errorDescriptionMessage = ""
        }
        if !graphQLRoutingErrors.contains(where: {$0.errorCode == errorCode}) {
            if !errorCode.isEmpty {
                graphQLRoutingErrors.append(RoutingErrors(errorCode: errorCode, displayText: errorTitleMessage, displaySubText: errorDescriptionMessage))
            }
        }
        if !originalGraphQLItineraries.isEmpty {
            graphQLRoutingErrors = graphQLRoutingErrors.filter({$0.errorCode != RoutingErrorCode.systemError.rawValue})
        }
    }
    
    /// Prepare transport view string.
    /// - Parameters:
    ///   - itinerary: Parameter description
    /// - Returns: String
    func prepareTransportViewString(itinerary : OTPItinerary) -> String{
        var returnString = ""
        if let legs = itinerary.legs{
            
            for index in 0..<legs.count{
                if index == 0 || index == getValidIndex(){
                    returnString.append(legs[index].searchMode?.label ?? "")
                    if index == 0 && index != legs.count - 1{
                        returnString.append(" to ")
                    }
                }
            }
            
            /// Get valid index
            /// - Returns: Int
            /// Retrieves valid index.
            func getValidIndex() -> Int{
                if legs.count > 2{
                    if legs[1].mode == "WALK"{
                        return 2
                    }
                }
                return 1
            }
        }
        return returnString
    }
    
    /// Transports time view.
    /// - Parameters:
    ///   - itinerary: Parameter description
    /// - Returns: some View
    func transportsTimeView(itinerary : OTPItinerary) -> some View {
        let (timeText, _) = self.timeText(for: String(itinerary.duration ?? 0))
        return VStack{
            HStack{
                TextLabel(timeText, .bold, .body)
                Spacer()
            }
            HStack{
                TextLabel(self.createShowTimeforEditTrip(itinerary: itinerary)).font(.footnote)
                    .foregroundColor(Color.gray)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
        }.frame(width: AccessibilityManager.shared.pubIsLargeFontSize ? (ScreenSize.width() - 60) : 100)
    }
    
    /// Saved trip list transports view.
    /// - Parameters:
    ///   - itinerary: Parameter description
    /// - Returns: some View
    func SavedTripListTransportsView(itinerary : OTPItinerary) -> some View {
        return HStack(spacing: 0){
            if let legs = itinerary.legs {
                let tripLegs = legs.map({ OTPTripLeg(leg: $0)})
                ForEach(0..<tripLegs.count, id: \.self ) { [self] index in
                    if index == 0 || index == getValidIndex(itinerary: itinerary){
                        
                        HStack(spacing: 0){
                            HStack(alignment: .center) {
                                Image(ModeManager.shared.getImageIconforSavedTrip(leg: tripLegs[index].leg))
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .padding(3)
                                    .background(Color(hex: tripLegs[index].leg.searchMode?.color ?? "#000000"))
                                    .foregroundColor(Color.white)
                            }
                            .frame(width: 30  ,height: 30)
                            .background(Color(hex: tripLegs[index].leg.searchMode?.color ?? "#000000"))
                            .cornerRadius(5)
                            
                            if index == 0 && index != legs.count - 1{
                                Image("ic_dash").frame(width: 20, height: 20)
                                    .accessibility(hidden: true)
                            }
                        }
                    }
                    else{
                        EmptyView()
                    }
                }
                Spacer().frame(width: 20)
            }
            else{
                EmptyView()
            }
        }
        .cornerRadius(5)
    }
    
    /// Get valid index.
    /// - Parameters:
    ///   - itinerary: Parameter description
    /// - Returns: Int
    func getValidIndex(itinerary : OTPItinerary) -> Int{
        if let legs = itinerary.legs,legs.count > 2{
            if legs[1].mode == "WALK"{
                return 2
            }
        }
        return 1
    }
    
    /// Saved trip list transports view a o d a.
    /// - Parameters:
    ///   - itinerary: Parameter description
    ///   - imageSize: Parameter description
    /// - Returns: some View
    func SavedTripListTransportsViewAODA(itinerary : OTPItinerary, imageSize: CGFloat) -> some View {
        return HStack(spacing: 0){
            if let legs = itinerary.legs {
                let tripLegs = legs.map({ OTPTripLeg(leg: $0)})
                ForEach(0..<tripLegs.count, id: \.self ) { [self] index in
                    if index == 0 || index == getValidIndex(itinerary: itinerary){
                        
                        HStack(spacing: 0){
                            HStack(alignment: .center) {
                                Image(tripLegs[index].leg.searchMode?.mode_image ?? "ic_bus")
                                    .renderingMode(.template)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .padding(3)
                                    .background(Color(hex: tripLegs[index].leg.searchMode?.color ?? "#000000"))
                                    .foregroundColor(Color.white)
                            }
                            .frame(width: imageSize  ,height: imageSize)
                            .background(Color(hex: tripLegs[index].leg.searchMode?.color ?? "#000000"))
                            .cornerRadius(5)
                            
                            if index == 0 && index != legs.count - 1{
                                Image("ic_dash").frame(width: imageSize - 20, height: 5)
                                    .accessibility(hidden: true)
                            }
                        }
                    }
                    else{
                        EmptyView()
                    }
                }
                Spacer().frame(width: imageSize - 20)
            }
            else{
                EmptyView()
            }
        }
        .cornerRadius(5)
    }
    
    /// Getaccessibility confidence for itinerary.
    /// - Parameters:
    ///   - itinerary: OTPItinerary
    /// - Returns: (AccessibilityScore, Color)
    func getaccessibilityConfidenceForItinerary(itinerary: OTPItinerary) -> (AccessibilityScore, Color) {
        if let score = itinerary.accessibilityScore {
            if score >= 0.0 && score < 0.5 {
                return (.notAccessible, Color.accessibility_red)
            } else if score >= 0.5 && score < 1 {
                return (.accessibilityUnknown, Color.accessibility_blue)
            } else if score == 1 {
                return (.accessible, Color.accessibility_green)
            }
        }
        return (.noInfo, Color.white)
    }
    
    /// Getaccessibility confidence for leg.
    /// - Parameters:
    ///   - leg: Parameter description
    /// - Returns: (AccessibilityScore, Color)
    func getaccessibilityConfidenceForLeg(leg: OTPLeg) -> (AccessibilityScore, Color) {
        if let score = leg.accessibilityScore {
            if score >= 0.0 && score < 0.5 {
                return (.notAccessible, Color.accessibility_red)
            } else if score >= 0.5 && score < 1 {
                return (.accessibilityUnknown, Color.accessibility_blue)
            } else if score == 1 {
                return (.accessible, Color.accessibility_green)
            }
        }
        return (.noInfo, Color.white)
    }
    
    /// Get route banner height.
    /// - Parameters:
    ///   - routeName: Parameter description
    ///   - isTripDetail: Parameter description
    /// - Returns: CGFloat
    func getRouteBannerHeight(routeName: String, isTripDetail: Bool = false) -> CGFloat {
        let width = CGFloat(30 + routeName.count * (AccessibilityManager.shared.pubIsLargeFontSize ? Int(AccessibilityManager.shared.getFontSize()) : 9))
        let imageWidth = AccessibilityManager.shared.pubIsLargeFontSize ? Int(AccessibilityManager.shared.getFontSize()) : 40
        var maxWidth: CGFloat = 0.0
        if isTripDetail {
            maxWidth = getRouteBannerWidth(routeName: routeName, isTripDetail: true)
        } else {
            maxWidth = (ScreenSize.width() - (CGFloat(imageWidth)) - (AccessibilityManager.shared.pubIsLargeFontSize ? 100 : 90))
        }
        let lines = width / maxWidth
        if lines < 0 {
            return 30
        } else {
            return (lines * 30)
        }
    }
    
    /// Get route banner width.
    /// - Parameters:
    ///   - routeName: Parameter description
    ///   - isTripDetail: Parameter description
    /// - Returns: CGFloat
    func getRouteBannerWidth(routeName: String, isTripDetail: Bool = false) -> CGFloat {
        var width = CGFloat(30 + routeName.count * (AccessibilityManager.shared.pubIsLargeFontSize ? Int(AccessibilityManager.shared.getFontSize()) : 10))
        let imageWidth = AccessibilityManager.shared.pubIsLargeFontSize ? Int(AccessibilityManager.shared.getFontSize()) : 40
        let maxWidth = (ScreenSize.width() - (CGFloat(imageWidth)) - (AccessibilityManager.shared.pubIsLargeFontSize ? 100 : 90))
        if (width >= maxWidth) {
            width = maxWidth
        }
        if isTripDetail {
            let geoWidth = (ScreenSize.width() - 100)
            if width > geoWidth / 2 {
                width = CGFloat(ScreenSize.width() / 2.5)
            }
        }
        return width
    }
    
    /// Get alerts array.
    /// - Parameters:
    ///   - leg: Parameter description
    /// - Returns: [OTPAlert?]
    func getAlertsArray(leg: OTPLeg?) -> [OTPAlert?]{
        var returnAlerts: [OTPAlert?] = []
        if let leg = leg {
            if let alerts = leg.alerts {
                returnAlerts.append(contentsOf: alerts)
            }
        }
        return returnAlerts
    }
    
    /// Render route info.
    /// - Parameters:
    ///   - routeShortName: Parameter description
    ///   - routeLongName: Parameter description
    ///   - headsign: Parameter description
    /// - Returns: String
    func renderRouteInfo(routeShortName: String, routeLongName: String, headsign: String) -> String {
        let hideRouteLongName = compareTwoStrings(headsign, routeLongName) > 0.25 || routeLongName.isEmpty
        if hideRouteLongName {
            if routeLongName.isEmpty || headsign.isEmpty {
                return routeShortName
            } else {
                return headsign.isEmpty ? routeLongName : headsign
            }
        } else {
            return "\(routeLongName) to \(headsign)"
        }
    }
    
    
    /// Compare two strings.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: Double
    func compareTwoStrings(_ string1: String, _ string2: String) -> Double {
        if string1.isEmpty && string2.isEmpty {
            return 1.0 // Both strings are empty
        }
        
        if string1.isEmpty || string2.isEmpty {
            return 0.0 // One string is empty
        }
        
        let distance = levenshteinDistance(string1, string2)
        let maxLength = Double(max(string1.count, string2.count))
        
        return (maxLength - Double(distance)) / maxLength
    }
    
    /// Levenshtein distance.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: Int
    func levenshteinDistance(_ lhs: String, _ rhs: String) -> Int {
        let lhsChars = Array(lhs)
        let rhsChars = Array(rhs)
        
        let lhsLength = lhsChars.count
        let rhsLength = rhsChars.count
        
        var distance = Array(repeating: Array(repeating: 0, count: rhsLength + 1), count: lhsLength + 1)
        
        for i in 0...lhsLength {
            distance[i][0] = i
        }
        
        for j in 0...rhsLength {
            distance[0][j] = j
        }
        
        for i in 1...lhsLength {
            for j in 1...rhsLength {
                if lhsChars[i - 1] == rhsChars[j - 1] {
                    distance[i][j] = distance[i - 1][j - 1]
                } else {
                    distance[i][j] = min(
                        distance[i - 1][j] + 1,
                        min(distance[i][j - 1] + 1, distance[i - 1][j - 1] + 1)
                    )
                }
            }
        }
        
        return distance[lhsLength][rhsLength]
    }
    
    // Logic for Sorting the Itinerary for Best Option
    // MARK: - Constants matching Web DEFAULT_WEIGHTS
    struct ItineraryWeights {
        var driveReluctance: Double = 2.0
        var durationFactor: Double = 0.25
        var fareFactor: Double = 0.5
        var transferReluctance: Double = 0.9
        var waitReluctance: Double = 0.1
        var walkReluctance: Double = 0.1

        static let `default` = ItineraryWeights()
    }

    // MARK: - Best Option Sorting : -Calculate itinerary cost ("rank") same as Web
    /// This calculates the "cost" (not the monetary cost, but the cost according to multiple factors like duration, total fare, and walking distance) for a particular itinerary, for use in sorting itineraries.
    func calculateItineraryCost(_ itinerary: OTPItinerary,weights: ItineraryWeights = .default,costsConfig: Any? = nil,defaultFareType: String? = nil) -> Double {
        
        // total fare (currency amount)
        let totalItineraryFare = getItineraryCost(itinerary: itinerary, mediumId: nil, riderCategoryId: nil)
        
        // penalty if missing fare, just like web's Number.MAX_VALUE
        let fareAmount = totalItineraryFare.amount

        // convert to Double where needed
        let duration = Double(itinerary.duration ?? 0)
        let walkDistance = getWalkDistance(itinerary: itinerary)
        let driveTime = getDriveTime(itinerary: itinerary)
        let waitingTime = getWaitingTime(itinerary: itinerary)
        let transfers = Double(getTransfersCount(itinerary: itinerary))

        // compute weighted sum
        let rank =
            (fareAmount * weights.fareFactor) +
            (duration * weights.durationFactor) +
            (walkDistance * weights.walkReluctance) +
            (driveTime * weights.driveReluctance) +
            (waitingTime * weights.waitReluctance) +
            (transfers * weights.transferReluctance)

        return rank
    }

    func getDriveTime(itinerary: OTPItinerary) -> Double {
        itinerary.legs?.reduce(0.0) { total, leg in
            if let mode = leg.mode?.lowercased(), mode == "car" || mode == "drive" {
                return total + (leg.duration ?? 0)
            }
            return total
        } ?? 0.0
    }

    func getWalkDistance(itinerary: OTPItinerary) -> Double {
        itinerary.legs?.reduce(0.0) { total, leg in
            if let mode = leg.mode?.lowercased(), mode == "walk" {
                return total + (leg.distance ?? 0)
            }
            return total
        } ?? 0.0
    }

    func getWaitingTime(itinerary: OTPItinerary) -> Double {
        Double(itinerary.waitingTime ?? 0)
    }

    func getTransfersCount(itinerary: OTPItinerary) -> Int {
        guard let legs = itinerary.legs else { return 0 }
        let transitLegs = legs.filter { leg in
            guard let mode = leg.mode?.lowercased() else { return true }
            return mode != "walk"
        }
        return max(0, transitLegs.count - 1)
    }
}
