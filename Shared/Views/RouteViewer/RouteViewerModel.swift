//
//  RouteViewerModel.swift
//

import SwiftUI
import Combine
import Mapbox

struct RouteSorting : Codable {
    let routeName: [String]
}

class RouteViewerModel: ObservableObject, RouteService {
	
	public static let MODE_COMPARATOR_VALUE_TRAM = 1;
	public static let MODE_COMPARATOR_VALUE_SUBWAY = 0;
	public static let MODE_COMPARATOR_VALUE_RAIL = 2;
	public static let MODE_COMPARATOR_VALUE_BUS = 3;
	public static let MODE_COMPARATOR_VALUE_FERRY = 4;
	public static let MODE_COMPARATOR_VALUE_CABLE_CAR = 5;
	public static let MODE_COMPARATOR_VALUE_GONDOLA = 6;
	public static let MODE_COMPARATOR_VALUE_FUNICULAR = 7;

	@Published var zoomLevel = Double(BrandConfig.shared.zoom_level)
    @Published var isLoading: Bool = false
    @Published var showAlert = false
    @Published var data: [StopViewerModel]? = nil
	@Published var pubRouteItems = [RouteItem]()
    @Published var pubHideSearchBar = false
    @Published var pubLastUpdated = Date().timeIntervalSince1970
    @Published var pubIsPresentRouteFilter = false
    
    private var routes: [TransitRoute] = []
    private var agency = [String: String]()
	
	// This is used to keep the origin route item set.
	public var originRouteItemsSet = [RouteItem]()
    
    var imagesDownloading = [String:Bool]();
    private let expire: TimeInterval = 86400  // expiration time (in seconds)

    public var agencyLogos = [String: UIImage]()
    /// Label: "otp.agency.logos.lock"
    /// Initializes a new instance.
    /// - Parameters:
    ///   - label: "otp.agency.logos.lock"
    private var agencyLogosLock = DispatchQueue.init(label: "otp.agency.logos.lock")
    public var agencyFilter = [String: [String]]()
	
 /// Filtered route items.
 /// - Parameters:
 ///   - [RouteItem]: Parameter description
	public var filteredRouteItems: [RouteItem] {
		get {
			var retFilteredRouteItems = [RouteItem]()
			let selectedAgency = RouteFilterPickerListViewModel.shared.pubSelectedAgency
			let selectedMode = RouteFilterPickerListViewModel.shared.pubSelectedMode
			let items = RouteViewerModel.shared.originRouteItemsSet
			for item in items {
                if selectedAgency == "All Agencies".localized() && selectedMode == "All Modes".localized() {
					retFilteredRouteItems.append(item)
                }
                // MARK: Hardcoded conditions needs to adjust later 
                else if selectedAgency == "All Agencies".localized() && selectedMode == "Water_Taxi".localized(){
                    if (item.route.id == "kcm:100336") || (item.route.id == "kcm:100337"){
                        retFilteredRouteItems.append(item)
                    }
                }
                else if selectedAgency == "All Agencies".localized() && selectedMode == "Ferry".localized(){
                    if let mode = item.route.mode{
                        if mode.rawValue.lowercased() == selectedMode.lowercased(){
                            retFilteredRouteItems.append(item)
                        }else if mode.rawValue.lowercased() == "water_taxi"{
                            let agencyModeAliases = FeatureConfig.shared.route_mode_overrides
                            for mode in agencyModeAliases {
                                if mode.aliase == "WATER_TAXI" && mode.id != "kcm:100336" && mode.id != "kcm:100337"{
                                    if item.route.id == mode.id{
                                        retFilteredRouteItems.append(item)
                                    }
                                }
                            }
                        }
                    }
                }
                else if selectedAgency == "Kitsap Transit".localized() && selectedMode == "Ferry".localized(){
                    if let mode = item.route.mode, mode.rawValue.lowercased() == "water_taxi"{
                        let agencyModeAliases = FeatureConfig.shared.route_mode_overrides
                        for mode in agencyModeAliases {
                            if mode.aliase == "WATER_TAXI" && mode.id != "kcm:100336" && mode.id != "kcm:100337"{
                                if item.route.id == mode.id{
                                    retFilteredRouteItems.append(item)
                                }
                            }
                        }
                    }
                }
                else if selectedAgency == "All Agencies".localized() {
                    if let mode = item.route.mode, mode.rawValue.lowercased() == selectedMode.lowercased(){
						retFilteredRouteItems.append(item)
					}
				}else if selectedMode == "All Modes".localized() {
					if item.route.agencyName == selectedAgency{
						retFilteredRouteItems.append(item)
					}
				}
				else
				{
					if let mode = item.route.mode, mode.rawValue.lowercased() == selectedMode.lowercased() && item.route.agencyName?.lowercased() == selectedAgency.lowercased() {
						retFilteredRouteItems.append(item)
					}
				}
			}
			return retFilteredRouteItems
		}
	}
    
 /// Unselect all route item
 /// Unselect all route item.
	public func unselectAllRouteItem(){
		var newStateRouteItems = [RouteItem]()
		for item in pubRouteItems {
			var newItem = item
			newItem.isSelected = false
			newStateRouteItems.append(newItem)
		}
        pubRouteItems = newStateRouteItems
	}
    
    /// Shared instance to hold the value.
    static var shared: RouteViewerModel = {
        let instance = RouteViewerModel()
        return instance
    }()
    
    private var cancellableSet = Set<AnyCancellable>()
    var service: APIServiceProtocol = APIService()
    var errorMessage: String = ""
    
    //MARK: Fetch GraphQL Routes
	let url = BrandConfig.shared.graphQL_base_url
    
    //MARK: added a temp solution
    var newSorting: [RouteSorting] = []
    
    /// Get route sort order.
    /// - Parameters:
    ///   - routes: Parameter description
    /// - Returns: [TransitRoute]
    func getRouteSortOrder(routes: [TransitRoute]) -> [TransitRoute]{
		var returnRoutes: [TransitRoute] = []
		var afterReturnRoutes: [TransitRoute] = []
		for route in routes {
			let cmpName = (route.shortName ?? "")+(route.longName ?? "")
            if !newSorting.contains(where: {$0.routeName.contains(cmpName)}) {
                afterReturnRoutes.append(route)
            }
		}
		for item in newSorting {
            let routeItem = routes.first(where: { item.routeName.contains((($0.shortName ?? "")+($0.longName ?? "")))})
			if let routeItem = routeItem {
				returnRoutes.append(routeItem)
			}
		}
        
		returnRoutes.append(contentsOf: afterReturnRoutes)
		return returnRoutes
    }
    
    /// Fetch graph q l routes
    /// Fetches graph ql routes.
    func fetchGraphQLRoutes(){
        let api = OTPAPIRequest()
        let requestQuery = GraphQLQueries.shared.routeList
        
        //MARK: - for requesting GraphQL Query from our APIManager, we need to pass Query and variable in key-value pair as paramaters
        let jsonKeyPair = [ "query" : "\(requestQuery)"] as [String : Any]
        
        api.request(method: .post, path: url, params: jsonKeyPair, headers: [:], format: .JSON) { data, error, response in
            
            guard let data = data else {
                OTPLog.log(level:.info, info:"cannot receive the route list response")
                return
            }
            
            if let err = error {
                OTPLog.log(level:.warning, info:"response from server for route list is failed, \(err.localizedDescription)")
                guard let _ = DataHelper.object(data) as? [String: Any] else {
                    OTPLog.log(level:.warning, info:"response from server for route list is failed, invalid error json data")
                    return
                }
                return
            }
            
            do{
                if let jsonData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let data = jsonData["data"] as? [String : Any]{
                        if let routes = data["routes"] as? [[String : Any]]{
                            if let routeData = try? JSONSerialization.data(withJSONObject:routes){
                                let routes = try JSONDecoder().decode([TransitRoute].self, from: routeData)
                                self.prepareRouteItemAndSorting(routes: routes)
                            }
                        }
                    }
                }
            }
            catch{
                OTPLog.log(level:.error, info: "can not decode the search modes, \(error.localizedDescription)")
            }
        }
    }
    
    func fetchSortedRoutes(){
        let api = OTPAPIRequest()
        let SortedRoutesURL = FeatureConfig.shared.sorted_route_order_url
        
        api.request(method: .get, path: SortedRoutesURL, headers: [:], format: .JSON) { data, error, response in
            
            guard let data = data else {
                OTPLog.log(level:.info, info:"cannot receive the sorted route list from S3 server")
                return
            }
            
            if let err = error {
                OTPLog.log(level:.warning, info:"response from S3 server for sorted route list is failed, \(err.localizedDescription)")
                guard let _ = DataHelper.object(data) as? [String: Any] else {
                    OTPLog.log(level:.warning, info:"response from S3 server for sorted route list is failed, invalid error json data")
                    return
                }
                return
            }
            
            do{
                let decodedData = try JSONDecoder().decode([RouteSorting].self, from: data)
                self.newSorting = decodedData
            }
            catch{
                OTPLog.log(level:.error, info: "can not decode the sorted route list, \(error.localizedDescription)")
            }
        }
    }
    
    /// Prepare route item and sorting.
    /// - Parameters:
    ///   - routes: Parameter description
    func prepareRouteItemAndSorting(routes: [TransitRoute]){
        var responseRoutes: [TransitRoute] = []
        for item in routes{
            if let agency = item.agency {
                let agency = Agency(id: agency.id, name: agency.name, url: agency.url, timezone: agency.timezone, lang: agency.lang, phone: agency.phone, fareUrl: agency.fareUrl)
                let route: TransitRoute = TransitRoute(id: item.id, agency: agency, shortName: item.shortName, longName: item.longName, type: item.type, color: item.color, textColor: item.textColor, eligibilityRestricted: 0, routeBikesAllowed: item.routeBikesAllowed ?? "0", bikesAllowed: item.bikesAllowed ?? "0", sortOrderSet: false, sortOrder: 0, agencyName: agency.name, agencyId: agency.id, url: agency.url, mode: item.mode ?? Mode(rawValue: "BUS"), desc: item.desc, patternId: nil, patterns: nil)
                responseRoutes.append(route)
            }
        }
        let newSortedRoutes = getRouteSortOrder(routes: responseRoutes)
        var newRouteItems = [RouteItem]()
        for route in newSortedRoutes {
            var newRoute = route
            //Check config to see if there are name and mode aliases
            newRoute = mapAgencyNameAliase(route: newRoute, aliases: FeatureConfig.shared.route_agency_name_mapping)
            newRoute = mapAgencyModeAliase(route: newRoute, aliases: FeatureConfig.shared.route_mode_overrides)

            let item = RouteItem(route: newRoute, isSelected: routeIsSelected(r: newRoute))
            newRouteItems.append(item)
            mapAgencyData(route: newRoute)
        }
        
        originRouteItemsSet = newRouteItems
        DispatchQueue.main.async { [self] in
            pubRouteItems = filteredRouteItems
        }
        saveAgencyDate()
        downloadAgencyLogo(routes: originRouteItemsSet)
        prepareAgenciesInfo(routes: originRouteItemsSet)
    }
    
    /// Get graph q l route info.
    /// - Parameters:
    ///   - route: Parameter description
    ///   - completion: Parameter description
    ///   - String?: Parameter description
    /// - Returns: Void))
    func getGraphQLRouteInfo(route: TransitRoute, completion: @escaping (([RoutePattern?]?, String?)->Void)) {
        
        let api = OTPAPIRequest()
        let requestQuery = GraphQLQueries.shared.routeInfo
        
        //MARK: - for requesting GraphQL Query from our APIManager, we need to pass Query and variable in key-value pair as paramaters
        let jsonKeyPair = [ "query" : "\(requestQuery)",
                            "variables" : [ "routeId" : "\(route.id)" ] ] as [String : Any]

        api.request(method: .post, path: url, params: jsonKeyPair, headers: [:], format: .JSON) { data, error, response in
            
            guard let data = data else {
                OTPLog.log(level:.info, info:"cannot receive the routeinfo list response")
                completion(nil, nil)
                return
            }
            
            if let err = error {
                OTPLog.log(level:.warning, info:"response from server for routeinfo list is failed, \(err.localizedDescription)")
                guard let _ = DataHelper.object(data) as? [String: Any] else {
                    OTPLog.log(level:.warning, info:"response from server for routeinfo list is failed, invalid error json data")
                    completion(nil, error?.localizedDescription)
                    return
                }
                completion(nil, error?.localizedDescription)
                return
            }
            
            do{
                if let jsonData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let data = jsonData["data"] as? [String : Any]{
                        if let route = data["route"] as? [String : Any]{
                            if let routeData = try? JSONSerialization.data(withJSONObject:route){
                                let route = try JSONDecoder().decode(TransitRoute.self, from: routeData)
                                completion(route.patterns, nil)
                            }
                        }
                    }
                }
            } catch {
                OTPLog.log(level:.error, info: "can not decode the search modes, \(error.localizedDescription)")
                completion(nil, error.localizedDescription)
            }
        }
        completion(nil, nil)
    }
    
    /// Refresh route items
    /// Refreshes route items.
    func refreshRouteItems(){
        var temp = [RouteItem]()
        for item in self.pubRouteItems{
            if item.isSelected{
                let routeItem = RouteItem(route: item.route, isSelected: false)
                temp.append(routeItem)
            }else{
                temp.append(item)
            }
        }
        self.pubRouteItems = temp
    }
    
    /// Map agency data.
    /// - Parameters:
    ///   - route: Parameter description
    func mapAgencyData(route: TransitRoute) {
        self.agency[route.id] = route.agencyId
    }
    
    /// Map agency name aliase.
    /// - Parameters:
    ///   - route: Parameter description
    ///   - aliases: Parameter description
    /// - Returns: TransitRoute
    func mapAgencyNameAliase(route: TransitRoute, aliases: [AgencyNameAliase]) -> TransitRoute{
        var resultRoute = route
        let originalName = route.agencyName

        for item in aliases{
            if item.name == originalName{
                resultRoute.agencyName = item.aliase
            }
        }
        
        return resultRoute
    }
    
    /// Map agency mode aliase.
    /// - Parameters:
    ///   - route: Parameter description
    ///   - aliases: Parameter description
    /// - Returns: TransitRoute
    func mapAgencyModeAliase(route: TransitRoute, aliases: [RouteModeOverride]) -> TransitRoute{
        var resultRoute = route
            // MARK: Fix it later
        for item in aliases{
            if item.id == resultRoute.id{
                resultRoute.mode = Mode(rawValue: item.aliase)
            }
        }
        return resultRoute
    }
    
    /// Save agency date
    /// Saves agency date.
    func saveAgencyDate() {
        let encoder = JSONEncoder()
        if let jsonData = try?encoder.encode(self.agency){
                if let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first{
                    var pathWithFileName = documentDirectory.appendingPathComponent("Agency")
                    pathWithFileName = pathWithFileName.appendingPathExtension("json")
                    do{
                        try jsonData.write(to: pathWithFileName)
                    }catch{
                        OTPLog.log(level: .error, info: "Error with Writing to Agency JSON File")
                    }
            }
        }
    }
    
    /// Download agency logo.
    /// - Parameters:
    ///   - routes: Parameter description
    func downloadAgencyLogo(routes: [RouteItem]) {
        agencyLogosLock.sync {
            for route in routes {
                var needToDownload = true
                
                let url = ImageProvider.getImageUrl(imageName: route.route.agencyName ?? "")
                let path = ImageProvider.docPath(route.route.agencyName ?? "N/A")
                
                if FileManager.default.fileExists(atPath: path.path) {
                    do {
                        let attrs = try FileManager.default.attributesOfItem(atPath: path.path)
                        if let creationDate = attrs[FileAttributeKey.modificationDate] as? Date {
                            if (Date().timeIntervalSince1970 - creationDate.timeIntervalSince1970) < expire {
                                needToDownload = false
                                let agencyLogoName = path.lastPathComponent.lowercased()
                                if let agencyLogo = UIImage(contentsOfFile: path.path) ?? UIImage(named: route.route.agencyName ?? "defaultAgencyLogo") {
                                    agencyLogos[agencyLogoName] = agencyLogo
                                } else {
                                    agencyLogos[agencyLogoName] = UIImage(named: "defaultAgencyLogo")
                                }
                            }
                        }
                    } catch {
                        OTPLog.log(level: .warning, info: "Can't load the image, \(error)")
                    }
                }
                
                if needToDownload {
                    var startToDownload = true
                    
                    if let downloading = imagesDownloading[url], downloading {
                        startToDownload = false
                    }
                    
                    if startToDownload {
                        imagesDownloading[url] = true
                        DataImageManager.shared.download(fromURL: url, toLocalPath: path.path) { [weak self] success in
                            guard let self = self else { return }
                            
                            self.imagesDownloading[url] = false
                            let agencyLogoName = path.lastPathComponent;
                            
                            if let agencyLogo = UIImage(contentsOfFile: path.path) ?? UIImage(named: route.route.agencyName ?? "defaultAgencyLogo") {
                                self.agencyLogos[agencyLogoName] = agencyLogo
                            } else {
                                self.agencyLogos[agencyLogoName] = UIImage(named: "defaultAgencyLogo")
                            }
                            
                            DispatchQueue.main.async {
                                self.pubLastUpdated = Date().timeIntervalSince1970
                            }
                        }
                    }
                }
            }
        }
    }
	
 /// Agencies.
 /// - Parameters:
 ///   - [String]: Parameter description
	public var agencies: [String] {
		var keys = agencyFilter.keys
		var availableAgencies = [String]()
		let _ = keys.map { availableAgencies.append($0) }
		return availableAgencies.sorted(by:<)
	}
	
 /// Modes for.
 /// - Parameters:
 ///   - agency: Parameter description
 /// - Returns: [String]
	public func modesFor(agency: String) -> [String] {
        var modes = [String]()
        var sortedModes = [String]()
		guard let agencyModes = agencyFilter[agency] else {
			return ["All Modes".localized()]
		}
        
        for mode in agencyModes {
            modes.append(mode.capitalized)
        }
        // MARK: Hardcoded needs to adjust later
        if agency == "Kitsap Transit".localized() {
            modes = modes.map { $0.lowercased() == "water_taxi" ? "Ferry" : $0 }
        }
        if !modes.isEmpty {
            sortedModes.append("All Modes".localized())
            sortedModes.append(contentsOf: modes.filter({$0 != "All Modes".localized()}).sorted(by: <))
        }
        return sortedModes.isEmpty ? modes.sorted(by: <) : sortedModes
	}
    
    /// Prepare agencies info.
    /// - Parameters:
    ///   - routes: Parameter description
    public func prepareAgenciesInfo(routes: [RouteItem]){
        agencyFilter.removeAll()
        var tempArray = [String]()
        tempArray.append("All Agencies".localized())
		
        for item in routes{
            if let agencyName = item.route.agencyName{
                if !tempArray.contains(agencyName){
                    tempArray.append(agencyName)
                }
            }
        }
		
        var tempModeArray = [String]()
        for agency in tempArray{
            tempModeArray.append(Mode.allMode.rawValue.localized())
			for item in routes{
				if let mode = item.route.mode, let agencyName = item.route.agencyName{
					
                    if agency == "All Agencies".localized(){
						if !tempModeArray.contains(mode.rawValue){
							tempModeArray.append(mode.rawValue)
						}
					}
					
					if agency == agencyName{
						if !tempModeArray.contains(mode.rawValue){
							tempModeArray.append(mode.rawValue)
						}
					}
				}
			}
			
            self.agencyFilter[agency] = tempModeArray
            tempModeArray.removeAll()
        }
    }
	
 /// Find route index.
 /// - Parameters:
 ///   - _: Parameter description
 ///   - selectedIndex: Parameter description
 /// - Returns: Void))
	public func findRouteIndex(_ id: String, selectedIndex:@escaping ((Int?)->Void)) {
		var index = -1
		let items = pubRouteItems
		var newItems = [RouteItem]()
		for i in 0..<items.count {
			var item = items[i]
			item.isSelected = false
			if item.route.id == id {
				index = i
				item.isSelected = true
			}
			newItems.append(item)
		}
		
		if index != -1 {
			
			DispatchQueue.main.async {
				self.pubRouteItems = newItems
			}
			
			DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
				selectedIndex(index)
			}
			
		}else{
			selectedIndex(nil)
		}
		
		
	}
	
 /// Route is selected.
 /// - Parameters:
 ///   - r: Parameter description
 /// - Returns: Bool
	private func routeIsSelected(r: TransitRoute)->Bool {
		let routeItemsCopy = self.pubRouteItems
		for routeItem in routeItemsCopy {
			let route = routeItem.route
			if let shortName = route.shortName, let rShortName = r.shortName, shortName == rShortName {
				return routeItem.isSelected
			}
		}
		return false
	}
	
 /// Map mode.
 /// - Parameters:
 ///   - _: Parameter description
 /// - Returns: Int
	private func mapMode(_ mode: Mode) -> Int{
		switch mode {
		case .tram:
			return RouteViewerModel.MODE_COMPARATOR_VALUE_TRAM
		case .subway:
			return RouteViewerModel.MODE_COMPARATOR_VALUE_SUBWAY
		case .rail:
			return RouteViewerModel.MODE_COMPARATOR_VALUE_RAIL
		case .bus:
			return RouteViewerModel.MODE_COMPARATOR_VALUE_BUS
		case .ferry:
			return RouteViewerModel.MODE_COMPARATOR_VALUE_FERRY
		case .cableCar:
			return RouteViewerModel.MODE_COMPARATOR_VALUE_CABLE_CAR
		case .gondola:
			return RouteViewerModel.MODE_COMPARATOR_VALUE_GONDOLA
		case .funicular:
			return RouteViewerModel.MODE_COMPARATOR_VALUE_FUNICULAR
		default:
			return 0
		}
	}
	
 /// Make multi criteria sort v2.
 /// - Parameters:
 ///   - routes: Parameter description
 /// - Returns: [TransitRoute]
	private func makeMultiCriteriaSortV2(routes: [TransitRoute]) -> [TransitRoute]{
		let sortedRoute = routes.sorted { preRoute, nxtRoute in
			if let preAgencyName = preRoute.agencyName, let nxtAgencyName = nxtRoute.agencyName, preAgencyName != nxtAgencyName {
				if(preAgencyName.contains("Metropolitan")){
					return false
				}
				else if(nxtAgencyName.contains("Metropolitan")){
					return true;
				}
				return preAgencyName < nxtAgencyName
			}
            else if let preRouteOrder = preRoute.sortOrder, let nxtRouteOrder = nxtRoute.sortOrder, preRouteOrder != nxtRouteOrder {
				return preRouteOrder < nxtRouteOrder
			}
			else if let preMode = preRoute.mode, let nxtMode = nxtRoute.mode, preMode != nxtMode {
				let mode1 = mapMode(preMode)
				let mode2 = mapMode(nxtMode)
				return (mode1 - mode2) < 0
			}
			else if let preShortName = preRoute.shortName, let nxtShortName = nxtRoute.shortName, preShortName != nxtShortName {
				if let preShortNameInt = Int(preShortName), let nxtShortNameInt = Int(nxtShortName) {
					return preShortNameInt < nxtShortNameInt
				}
				if let _ = Int(preShortName) { return false }
				else if let _ = Int(nxtShortName) { return true }
				return preShortName < nxtShortName
			}
			else{
				var preShortInt = false
				var nxtShortInt = false
				if let preShortName = preRoute.shortName {
					if let _ = Int(preShortName) { preShortInt = true }
				}
				if let nxtShortName = nxtRoute.shortName {
					if let _ = Int(nxtShortName) { nxtShortInt = true }
				}
				if preShortInt && !nxtShortInt {
					return true
				}else{
					if let preLongName = preRoute.longName, let nxtLongName = nxtRoute.longName, preLongName != nxtLongName
					{
						return preLongName < nxtLongName
					}
				}
			}
			
			return false
		}
		return sortedRoute
	}
    
    /// Sort using agency.
    /// - Parameters:
    ///   - routes: Parameter description
    /// - Returns: [TransitRoute]
    private func sortUsingAgency(routes: [TransitRoute]) -> [TransitRoute]{
        var sortedRoute: [TransitRoute] = []
        for i in 1...6{
            var temp: [TransitRoute] = []
            for item in routes{
                if getAgencyPriority(agencyName: item.agencyName ?? "") == i{
                    temp.append(item)
                }
            }
            sortedRoute.append(contentsOf: temp)
        }
        return sortedRoute
    }

    /// Get agency priority.
    /// - Parameters:
    ///   - agencyName: Parameter description
    /// - Returns: Int
    private func getAgencyPriority(agencyName: String) -> Int{
        switch agencyName {
        case "Metropolitan Atlanta Rapid Transit Authority":
            return 1
        case "Cherokee Area Transportation System (CATS)":
            return 2
        case "CobbLinc":
            return 3
        case "Connect Douglas":
            return 4
        case "Gwinnett County Transit":
            return 5
        case "Xpress":
            return 6
        case "C-TRAN":
            return 2
        case "SMART" :
            return 3
        case "Portland Aerial Tram":
            return 4
        case "Portland Streetcar":
            return 5
        default:
            return 1
        }
    }
	
 /// Make multi criteria sort.
 /// - Parameters:
 ///   - routes: Parameter description
 /// - Returns: [TransitRoute]
	private func makeMultiCriteriaSort(routes: [TransitRoute]) -> [TransitRoute]{
		let sortedRoute = routes.sorted { preRoute, nxtRoute in
			let ascOrderFlag = -1

			let level1Compare = makeTransitOperatorSort(preRoute, nxtRoute)
			if level1Compare != 0 { return level1Compare == ascOrderFlag }
			
			let level2Compare = makeNumericValueComparatorV1(preRoute, nxtRoute)
			if level2Compare != 0 { return level2Compare == ascOrderFlag }
			
			let level3Compare = routeTypeComparator(preRoute, nxtRoute)
			if level3Compare != 0 { return level3Compare == ascOrderFlag }
			
			let level4Compare = alphabeticShortNameComparator(preRoute, nxtRoute)
			if level4Compare != 0 {return level4Compare == ascOrderFlag}
			
			let level5Compare = makeNumericValueComparatorV2(preRoute, nxtRoute)
			if level5Compare != 0 {return level5Compare == ascOrderFlag}
			
			let level6Compare = makeStringShortNameComparator(preRoute, nxtRoute)
			if level6Compare != 0 {return level6Compare == ascOrderFlag}
			
			let level7Compare = makeStringLongNameComparator(preRoute, nxtRoute)
			if level7Compare != 0 {return level7Compare == ascOrderFlag}
			
			return false
		}
		return sortedRoute
	}
	
 /// Make string short name comparator.
 /// - Parameters:
 ///   - _: Parameter description
 /// - Returns: Int
	private func makeStringShortNameComparator(_ preRoute: TransitRoute, _ nxtRoute: TransitRoute) -> Int{
		return makeStringComparator(preRoute.shortName, nxtRoute.shortName)
	}
	
 /// Make string long name comparator.
 /// - Parameters:
 ///   - _: Parameter description
 /// - Returns: Int
	private func makeStringLongNameComparator(_ preRoute: TransitRoute, _ nxtRoute: TransitRoute) -> Int{
		return makeStringComparator(preRoute.longName, nxtRoute.longName)
	}
	
 /// Make string comparator.
 /// - Parameters:
 ///   - _: Parameter description
 /// - Returns: Int
	private func makeStringComparator(_ aVal: String?, _ bVal: String?) -> Int{
		
		if let a = aVal, let b = bVal {
			if a.compare(b) == .orderedAscending { return -1 }
			if a.compare(b) == .orderedDescending {return 1}
		}
		
		if let _ = aVal { return -1}
		if let _ = bVal { return 1}
		
		return 0
	}
	
 /// Make numeric value comparator v2.
 /// - Parameters:
 ///   - _: Parameter description
 /// - Returns: Int
	private func makeNumericValueComparatorV2(_ preRoute: TransitRoute, _ nxtRoute: TransitRoute) -> Int{
		var aVal: Int? = nil
		var bVal: Int? = nil
		if let aShortName = preRoute.shortName {
			aVal = Int(aShortName)
		}
		if let bShortName = nxtRoute.shortName {
			bVal = Int(bShortName)
		}
		if aVal == nil && bVal == nil {
			return 0
		}
		
		if aVal == nil {
			return 1
		}
		
		if bVal == nil {
			return -1
		}
		
		if let a = aVal, let b = bVal {
			return a - b > 0 ? 1 : -1
		}
		
		return 0
	}
	
 /// Alphabetic short name comparator.
 /// - Parameters:
 ///   - _: Parameter description
 /// - Returns: Int
	private func alphabeticShortNameComparator(_ preRoute: TransitRoute, _ nxtRoute: TransitRoute) -> Int{
		var aStartsWithAlphabeticCharacter = false
		if let shortName = preRoute.shortName {
			aStartsWithAlphabeticCharacter = startsWithAlphabeticCharacter(val:shortName)
		}
		var bStartsWithAlphabeticCharacter = false
		if let shortName = nxtRoute.shortName {
			bStartsWithAlphabeticCharacter = startsWithAlphabeticCharacter(val:shortName)
		}
		if aStartsWithAlphabeticCharacter && bStartsWithAlphabeticCharacter {
			return 0
		}
		if aStartsWithAlphabeticCharacter { return -1 }
		if bStartsWithAlphabeticCharacter { return 1 }
		return 0
	}
	
 /// Starts with alphabetic character.
 /// - Parameters:
 ///   - val: Parameter description
 /// - Returns: Bool
	private func startsWithAlphabeticCharacter(val: String) -> Bool {
		if val.count > 0 {
			if let firstCharCode = val[val.startIndex].asciiValue {
				return firstCharCode >= 65 && firstCharCode<=90 || firstCharCode >= 97 && firstCharCode <= 122
			}
		}
		return false
	}
	
 /// Route type comparator.
 /// - Parameters:
 ///   - _: Parameter description
 /// - Returns: Int
	private func routeTypeComparator(_ preRoute: TransitRoute, _ nxtRoute: TransitRoute) -> Int{
		let aVal = getRouteTypeComparatorValue(preRoute)
		let bVal = getRouteTypeComparatorValue(nxtRoute)
		return aVal - bVal
	}
	
 /// Get route type comparator value.
 /// - Parameters:
 ///   - _: Parameter description
 /// - Returns: Int
	private func getRouteTypeComparatorValue(_ route: TransitRoute) -> Int {
  /// Mode comparator value.
  /// - Parameters:
  ///   - _: Parameter description
  /// - Returns: Int
		func modeComparatorValue(_ mode: String) -> Int{
			switch(mode.lowercased()){
			case "subway": return 1
			case "tram": return 2
			case "rail": return 3
			case "gondola": return 4
			case "ferry": return 5
			case "cable_car": return 6
			case "funicular":return 7
			case "bus": return 8
			default:return -1
			}
		}
		
  /// Route type comparator value.
  /// - Parameters:
  ///   - _: Parameter description
  /// - Returns: Int
		func routeTypeComparatorValue(_ type: Int) -> Int {
			let typeMapping = [
				0:modeComparatorValue("tram"),
				1:modeComparatorValue("subway"),
				2:modeComparatorValue("rail"),
				3:modeComparatorValue("bus"),
				4:modeComparatorValue("ferry"),
				5:modeComparatorValue("cable_car"),
				6:modeComparatorValue("gondola"),
				7:modeComparatorValue("funicular"),
				11:modeComparatorValue("bus"),
				12:modeComparatorValue("rail")
			]
			
			if let typeInt = typeMapping[type] {
				return typeInt
			}
			
			return -1
		}
		
		if let unwrappedMode = route.mode?.rawValue {
			let val = modeComparatorValue(unwrappedMode)
			if val != -1 {return val}
		}
		
		if let unwrappedType = route.type {
			let val = routeTypeComparatorValue(unwrappedType)
			if val != -1 {return val}
		}
			
		return 0
	}
	
 /// Make numeric value comparator v1.
 /// - Parameters:
 ///   - _: Parameter description
 /// - Returns: Int
	private func makeNumericValueComparatorV1(_ preRoute: TransitRoute, _ nxtRoute: TransitRoute) -> Int{
        guard let preRouteOrder = preRoute.sortOrder else {return 0}
        guard let nextRouteOrder = nxtRoute.sortOrder else {return 0}
            
  /// Get route sort order value.
  /// - Parameters:
  ///   - val: Parameter description
  /// - Returns: Int?
		func getRouteSortOrderValue(val:Int) -> Int?{
			return val == -999 ? nil : val
		}
		let aVal = getRouteSortOrderValue(val: preRouteOrder)
		let bVal = getRouteSortOrderValue(val: nextRouteOrder)
		if aVal == nil && bVal == nil {
			return 0
		}
		if aVal == nil { return 1 }
		if bVal == nil { return -1 }
		let a = aVal ?? 0
		let b = bVal ?? 0
		return a - b
	}
	
 /// Make transit operator sort.
 /// - Parameters:
 ///   - _: Parameter description
 /// - Returns: Int
	private func makeTransitOperatorSort(_ preRoute: TransitRoute, _ nxtRoute: TransitRoute) -> Int{
		let aVal = getTransitOperatorComparatorValue(route: preRoute)
		let bVal = getTransitOperatorComparatorValue(route: nxtRoute)
		if aVal < bVal { return -1 }
		if aVal > bVal {return 1}
		return 0
	}
	
 /// Get transit operator comparator value.
 /// - Parameters:
 ///   - route: Parameter description
 /// - Returns: String
	private func getTransitOperatorComparatorValue(route: TransitRoute) -> String {
		
		if let agency = route.agency {
			let agencyName = agency.name
			return agencyName
		}
		
		if let agencyName = route.agencyName {
			return agencyName
		}
		
		return "zzz"
	}
}
