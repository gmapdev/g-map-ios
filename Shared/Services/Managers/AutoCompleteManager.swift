//
//  AutoCompleteManager.swift
//

import Foundation
import SwiftUI
import Combine

struct AutoCompleteSection {
	 var sectionTitle: String
	 var sectionItems: [AutoCompleteItem]
	 var displayStyle: AutoCompleteDisplayStyle
	 var displayTitle: Bool
}

struct AutoCompleteItem {
	var id: String = UUID().uuidString
	var title: String
	var subTitle: String?
    var agencyTitle: String?
    var mode: Mode?
    var tagNumber: String?
    var tagColor: String?
	var imageName: String?
	var imageWithMask: Bool
	var userInfo: Any?
	var onTap: ((String?, Any?)->Void)?
}

enum AutoCompleteDisplayStyle: String{
	  case plainText
	  case imageBeforeText
	  case imageWithTitleAndSubTitle
      case tagWithImageTitleAndSubTitle
}

enum AutoCompleteMode: String {
	case route = "route"
	case stopList = "stopList"
}

enum AutoCompleteItemType: String {
    case stopLocation = "stops"
    case otherLocation = "venue"
    case addressLocation = "address"
}

class AutoCompleteManager: ObservableObject {
    @ObservedObject var routeManager = RouteManager.shared
    @Published var pubFilteredItems = [AutoCompleteSection]()
	@Published var pubOpenPage = false
	@Published var pubFilterKeywordForRoute = ""
	@Published var pubFilterKeywordForStop = ""
    @ObservedObject var routeFilterPickerModel = RouteFilterPickerListViewModel.shared
	
 /// Pub keyword.
 /// - Parameters:
 ///   - String: Parameter description
	var pubKeyword: String {
		get {
			if autoCompleteMode == .stopList {
				return pubFilterKeywordForStop
			}
			return pubFilterKeywordForRoute
		}
		set{
			if autoCompleteMode == .stopList {
				pubFilterKeywordForStop = newValue
			}
			else if autoCompleteMode == .route {
				pubFilterKeywordForRoute = newValue
			}
		}
	}
	
	var didChange = PassthroughSubject<String,Never>()
	
	var autoCompleteMode: AutoCompleteMode = .route
	var placeholder: String = "Search for a keyword"
	var textImageName: String = "ic_search"
	
	var autoCompleteTimer: Timer?
	
 /// Shared.
 /// - Parameters:
 ///   - AutoCompleteManager: Parameter description
	public static var shared: AutoCompleteManager = {
		let mgr = AutoCompleteManager()
		return mgr
	}()
	
 /// Load sections.
 /// - Parameters:
 ///   - keywords: Parameter description
 /// Loads sections.
	public func loadSections(keywords: String){
		if let timer = self.autoCompleteTimer {
			timer.invalidate()
			self.autoCompleteTimer = nil
		}
		
		self.autoCompleteTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { timer in
			DispatchQueue.main.async {
				if self.autoCompleteMode == .route {
					self.routeSections(keywords)
				}else if self.autoCompleteMode == .stopList {
                    if keywords.count >= 2{
                        self.stopListSection(keywords)
                    }
				}
			}
		})
	}
	
 /// Is valid stop.
 /// - Parameters:
 ///   - _: Parameter description
 ///   - keywords: Parameter description
 /// - Returns: Bool
	private func isValidStop(_ item: Stop, keywords: String) -> Bool {
        var result = item.name.lowercased().contains(keywords.lowercased())
		result = result || item.name.lowercased().contains(keywords.lowercased())
		return result
	}
    
    /// Is valid stop i d.
    /// - Parameters:
    ///   - _: Parameter description
    ///   - keywords: Parameter description
    /// - Returns: Bool
    private func isValidStopID(_ item: Stop, keywords: String) -> Bool{
        var result = item.id.contains(keywords)
        result = result || item.id.contains(keywords)
        return result
    }
	
 /// Is valid route.
 /// - Parameters:
 ///   - _: Parameter description
 ///   - keywords: Parameter description
 /// - Returns: Bool
	private func isValidRoute(_ item: RouteItem, keywords: String) -> Bool {
		var result = item.route.busRouteNumber.contains(keywords)
		if let agencyName = item.route.agencyName {
			result = result || agencyName.lowercased().contains(keywords.lowercased())
		}
		if let longName = item.route.longName {
			result = result || longName.lowercased().contains(keywords.lowercased())
		}
		if let shortName = item.route.shortName {
			result = result || shortName.lowercased().contains(keywords.lowercased())
		}
		result = result || item.route.title.contains(keywords)
		if let agencyName = item.route.agency?.name {
			result = result || agencyName.lowercased().contains(keywords.lowercased())
		}
		
		if keywords.count == 0 {
			return true
		}
		
		return result
	}
	
 /// Route sections.
 /// - Parameters:
 ///   - _: Parameter description
	private func routeSections(_ keywords: String ){
		var items = [AutoCompleteItem]()
        let routeItems = RouteViewerModel.shared.filteredRouteItems
		for route in routeItems {
			if isValidRoute(route, keywords: keywords){
                let routeTitle = route.route.longName ?? route.route.title
                let atItem = AutoCompleteItem(title:  routeTitle,
                                              subTitle: (route.route.agencyName ?? ""), agencyTitle: (route.route.agencyName ?? ""), mode: route.route.mode, tagNumber: route.route.busRouteNumber, tagColor: route.route.color,
                                              imageName: route.route.searchMode?.mode_image, imageWithMask: true, userInfo: nil) { title, userInfo in
					DispatchQueue.main.async {
						self.pubOpenPage = false
                        self.didChange.send(route.route.id)
                        self.showRouteInfo(route: route)
					}
				}
				items.append(atItem)
			}
		}
        let title = items.count > 0 ? "%1 Routes Found".localized("\(items.count)") : "No routes match your filter!".localized()
		let section = AutoCompleteSection(sectionTitle: title, sectionItems: items, displayStyle: .tagWithImageTitleAndSubTitle, displayTitle: true)
		
        DispatchQueue.main.async {
            self.pubFilteredItems = [section]
        }
	}
    
    /// Filter route items
    /// - Returns: [AutoCompleteItem]
    /// Filters route items.
    func filterRouteItems() -> [AutoCompleteItem]{
        var returnItems = [AutoCompleteItem]()
        if pubFilteredItems.count > 0 {
            let routeItems = pubFilteredItems[0].sectionItems
            let filterAgency = routeFilterPickerModel.pubSelectedAgency
            let filtermode = routeFilterPickerModel.pubSelectedMode
            for item in routeItems{
                if filterAgency == "All Agencies".localized() && filtermode == "All Modes".localized() {
                    returnItems.append(item)
                }else if filterAgency == "All Agencies".localized() {
                    if let mode = item.mode, mode.rawValue.lowercased() == filtermode.lowercased(){
                        returnItems.append(item)
                    }
                }else if filtermode == "All Modes".localized() {
                    if item.agencyTitle == filterAgency{
                        returnItems.append(item)
                    }
                }
                else
                {
                    if let mode = item.mode, let agencyName = item.agencyTitle, mode.rawValue.lowercased() == filtermode.lowercased() && agencyName.lowercased() == filterAgency.lowercased() {
                        returnItems.append(item)
                    }
                }
                
            }
        }
        return returnItems
    }
    
    /// Show route info.
    /// - Parameters:
    ///   - route: Parameter description
    /// Shows route info.
    private func showRouteInfo(route: RouteItem){
        routeManager.showRouteInfo(route: route)
    }
    
    /// Stop list section.
    /// - Parameters:
    ///   - _: Parameter description
    /// Stops list section.
    private func stopListSection(_ input: String){
		let keywords = input.trimmingCharacters(in: CharacterSet.whitespaces)
        let locations = MapManager.shared.stops
        if locations.count > 0{
            var items = [AutoCompleteItem]()
            for location in locations {
                if keywords.isInt {
                    if isValidStopID(location, keywords: keywords){
                        let atItem = AutoCompleteItem(id: location.name, title: location.name,
                                                      subTitle: "Stop Id: %1".localized(location.id.removeStopIDPrefix),
                                                      imageName: "ic_stops", imageWithMask: true, userInfo: location.id) { title, stopId in
                            DispatchQueue.main.async {
                                self.pubOpenPage = false
                                if let finalTitle = title {
                                    self.pubFilterKeywordForStop = finalTitle
                                }
                                
                                if let stopId = stopId as? String {
                                    self.didChange.send("\(stopId)")
                                }
                            }
                        }
                        var existed = false
                        for item in items {
                            if item.title == location.name{
                                existed = true
                                break
                            }
                        }
                        if !existed{
                            items.append(atItem)
                        }
                    }
                }
                else{
                    if isValidStop(location, keywords: keywords){
                        let stopId = StopsManager.shared.findStopByName(stopName: location.name)?.id ?? "N/A"
                        let atItem = AutoCompleteItem(id: location.name, title: location.name,
                                                      subTitle: "Stop Id: %1".localized(stopId.removeStopIDPrefix),
                                                      imageName: "ic_stops", imageWithMask: true, userInfo: stopId) { title, stopId in
                            DispatchQueue.main.async {
                                self.pubOpenPage = false
                                if let finalTitle = title {
                                    self.pubFilterKeywordForStop = finalTitle
                                }
                                
                                if let stopId = stopId as? String {
                                    self.didChange.send("\(stopId)")
                                }
                            }
                        }
                        var existed = false
                        for item in items {
                            if item.title == location.name{
                                existed = true
                                break
                            }
                        }
                        if !existed{
                            items.append(atItem)
                        }
                    }
                }
            }
            let section = AutoCompleteSection(sectionTitle: items.count>0 ? "%1 Stops Found".localized(items.count) : "No stops found".localized(), sectionItems: items, displayStyle: .imageWithTitleAndSubTitle, displayTitle: true)
            
            DispatchQueue.main.async {
                self.pubFilteredItems = [section]
            }
        }
        else{
            let section = AutoCompleteSection(sectionTitle: "No stops are available to be found", sectionItems: [], displayStyle: .imageWithTitleAndSubTitle, displayTitle: true)

            DispatchQueue.main.async {
                self.pubFilteredItems = [section]
            }
        }
        
        if let login = AppSession.shared.loginInfo {
            favoriteStopsListSection(login: login)
        }
    }
    
    /// Favorite stops list section.
    /// - Parameters:
    ///   - login: Parameter description
    func favoriteStopsListSection(login: LoginInfo) {
        if let locations = login.savedLocations, locations.count > 0{
            var favoriteStops = [AutoCompleteItem]()
            for location in locations {
                if location.type == "stop"{
                    let stopId = StopsManager.shared.findStopByName(stopName: location.address)?.id ?? "N/A"
                    let atItem = AutoCompleteItem(title: location.address,
                                                  subTitle: "Stop Id: %1".localized(stopId.removeStopIDPrefix),
                        imageName: "ic_saved", imageWithMask: true, userInfo: stopId) { title, stopId in
                        DispatchQueue.main.async {
                            self.pubOpenPage = false
                            if let finalTitle = title {
                                self.pubFilterKeywordForStop = finalTitle
                            }
                            
                            if let stopId = stopId as? String {
                                self.didChange.send("\(stopId)")
                            }
                        }
                    }
                    favoriteStops.append(atItem)
                }
            }
            
            if favoriteStops.count > 0 {
                let section = AutoCompleteSection(sectionTitle: "My Favorite Stops".localized(), sectionItems: favoriteStops, displayStyle: .imageWithTitleAndSubTitle, displayTitle: true)
                
                DispatchQueue.main.async {
                    if self.pubFilteredItems.count > 0 {
                        self.pubFilteredItems.append(section)
                    }else{
                        self.pubFilteredItems = [section]
                    }
                }
            }
        }
    }
	
}
