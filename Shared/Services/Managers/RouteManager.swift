//
//  RouteManager.swift
//

import Foundation
import Combine
import SwiftUI
import Mapbox


class RouteManager: ObservableObject, RouteService {
    @ObservedObject var bottomSlideBarModel = BottomSlideBarViewModel.shared
    @ObservedObject var mapManager = MapManager.shared
    
    @Published var pubDetails: TransitRoute? = nil
    
    @Published var pubGeometry: [Geometry]?
    @Published var pubPatternsData: [RoutePattern?]?
    @Published var pubDirectionStops = [Stop]()
    @Published var isLoading: Bool = false
    private var routeId: String?
    private var cancellableSet = Set<AnyCancellable>()
    
    var realTimeBusInfoRefreshInterval = BrandConfig.shared.realtime_businfo_refresh_interval
    
    var service: APIServiceProtocol = APIService()
    var selectedRoute:TransitRoute?
    var selectedDirectionGeoData:Geometry?
    var selectedDirectionLegGeoData:String?
    
    private var busUpdateTimer: Timer?
    private var currentRoute: TransitRoute?
    
    /// Shared.
    /// - Parameters:
    ///   - RouteManager: Parameter description
    static var shared: RouteManager = {
        let mgr = RouteManager()
        return mgr
    }()
    
    @Inject var busInfoProvider: BusInfoProvider
    
    /// Present bus route.
    /// - Parameters:
    ///   - route: Parameter description
    /// Presents bus route.
    func presentBusRoute(route: TransitRoute){
        getRouteDetails(route: route)
    }
    
    /// Show route info.
    /// - Parameters:
    ///   - route: Parameter description
    /// Shows route info.
    func showRouteInfo(route: RouteItem){
        mapManager.deSelectAnnotations()
        mapManager.cleanPlotRoute()
        RouteViewerModel.shared.unselectAllRouteItem()
        self.selectedRoute = route.route
        self.getRouteDetails(route: route.route)
        mapManager.removeRealTimeBusMarker()
        // check weather we need to get real time bus for Ferry and WaterTaxi. since they are not vehicle, no need to show.
        if let routeMode = route.route.mode, routeMode != .ferry && routeMode != .water_taxi {
            self.getRealtimeBusData(route: route.route, pattern: nil)
        }
        RouteViewerModel.shared.pubHideSearchBar = true
        self.pubDirectionStops.removeAll()
    }
    
    /// Present bus route.
    /// - Parameters:
    ///   - id: Parameter description
    ///   - patternId: Parameter description
    func presentBusRoute(id: String, patternId: String? = nil){
        mapManager.cleanPlotRoute()
    }
    
    /// Get route details.
    /// - Parameters:
    ///   - route: Parameter description
    /// Retrieves route details.
    func getRouteDetails(route: TransitRoute) {
        self.pubDetails = route
        RouteViewerModel.shared.getGraphQLRouteInfo(route: route) { routePatterns, error in
            if let error = error {
                OTPLog.log(level: .error, info: "\(error)")
                return
            }
            var patterns: [RoutePattern?] = []
            patterns = self.findLargestStopSetV3(route: route ,routePatterns: routePatterns ?? [])
            if patterns.count > 0 {
                var tempGeometry: [Geometry] = []
                for geoData in patterns {
                    if let geoData = geoData, let patternGeometry =  geoData.patternGeometry, let points = patternGeometry.points, let length = patternGeometry.length{
                        let headSign = geoData.headsign ?? geoData.name ?? route.longName ?? ""
                        let legGeometry = LegGeometry(points: points, length: length)
                        let geo = Geometry(id: geoData.id, desc: headSign, geometry: legGeometry)
                        tempGeometry.append(geo)
                    }
                }
                DispatchQueue.main.async {
                    self.pubGeometry = tempGeometry
                    self.pubPatternsData = patterns
                    if let pattern = patterns[0], let patternGeometry = pattern.patternGeometry, let points = patternGeometry.points {
                        self.selectedDirectionLegGeoData = points
                        self.showGeoRouteOnMap(geoPoints: points, route: route)
                    }
                }
            }
        }
    }
    
    /// Find duplicates direction title.
    /// - Parameters:
    ///   - routePatterns: Parameter description
    /// - Returns: [String]
    func findDuplicatesDirectionTitle(routePatterns: [RoutePattern?]) -> [String] {
            var duplicates = [String]()
            var nameSet = Set<String>()
            
            for route in routePatterns {
                if let route = route, let name = route.headsign {
                    if nameSet.contains(name) && !duplicates.contains(name) {
                        duplicates.append(name)
                    } else {
                        nameSet.insert(name)
                    }
                }
            }
            return duplicates
        }
    
    /// Find largest stop set.
    /// - Parameters:
    ///   - routePatterns: Parameter description
    /// - Returns: [RoutePattern?]
    func findLargestStopSet(routePatterns: [RoutePattern?]) -> [RoutePattern?]{
        let filteredPattern = filterSubsetsFromSuperSet(routePattern: routePatterns)
        var returnedPattern: [RoutePattern?] = []
        for item in routePatterns {
            if !filteredPattern.contains(item) {
                returnedPattern.append(item)
            }
        }
        return returnedPattern
    }
    
    /// Find largest stop set v2.
    /// - Parameters:
    ///   - routePatterns: Parameter description
    /// - Returns: [RoutePattern?]
    func findLargestStopSetV2(routePatterns: [RoutePattern?]) -> [RoutePattern?] {
        var routePatterns = routePatterns
        let duplicates = self.findDuplicatesDirectionTitle(routePatterns: routePatterns)
        let uniqueDuplicates = Helper.shared.removeDuplicates(from: duplicates)
        for item in uniqueDuplicates {
            var maxPattern: RoutePattern? = nil
            let duplicatePatterns = routePatterns.filter({$0?.headsign == item})
            for geoData in duplicatePatterns {
                if let geoData = geoData , let geometry = geoData.patternGeometry, let geoPoints = geometry.points {
                    guard let decodedCoordinates = Polyline(encodedPolyline: geoPoints).coordinates else { return routePatterns}
                    if maxPattern == nil {
                        maxPattern = geoData
                    } else {
                        if let geoData = maxPattern , let geometry = geoData.patternGeometry, let geoPoints = geometry.points {
                            guard let maxDecodedCoordinates = Polyline(encodedPolyline: geoPoints).coordinates else { return routePatterns}
                            if decodedCoordinates.count > maxDecodedCoordinates.count {
                                maxPattern = geoData
                            }
                        }
                    }
                }
            }
            routePatterns.removeAll(where: {$0?.headsign == item})
            routePatterns.append(maxPattern)
        }
        return routePatterns
    }
    /// Find largest stop set v3.
    /// - Parameters:
    ///   - route: Parameter description
    ///   - routePatterns: Parameter description
    /// - Returns: [RoutePattern?]
    func findLargestStopSetV3(route: TransitRoute, routePatterns: [RoutePattern?]) -> [RoutePattern?] {
        
        let sortedPatterns = routePatterns.sorted { r1, r2 in
            r1?.patternGeometry?.length ?? 0 > r2?.patternGeometry?.length ?? 0
        }
        var filteredLargestPatterns = findLargestStopSet(routePatterns: sortedPatterns)
        if filteredLargestPatterns.count == 1 {
            filteredLargestPatterns = sortedPatterns
        }
        let finalPatterns = findLargestStopSetV4(route: route, routePatterns: filteredLargestPatterns)
        return finalPatterns
    }
    
    /// Find largest stop set v4.
    /// - Parameters:
    ///   - route: Parameter description
    ///   - routePatterns: Parameter description
    /// - Returns: [RoutePattern?]
    func findLargestStopSetV4(route: TransitRoute, routePatterns: [RoutePattern?]) -> [RoutePattern?] {

        let duplicateRoutePatterns = self.findDuplicatesDirectionTitle(routePatterns: routePatterns)
        var newRoutePatterns: [RoutePattern?] = []
        for item in routePatterns {
            if let item = item {
                let headsign = item.headsign ?? ""
                let occurrences = routePatterns.filter({$0?.headsign == headsign}).count
                if duplicateRoutePatterns.contains(headsign) && occurrences == 2{
                    if let stops = item.stops, !stops.isEmpty {
                        let stopName = stops[stops.count - 1].name
                        if headsign != stopName {
                            let newHeadSign = headsign + " *(" + "\(stopName)" + ")*"
                            let newPattern = RoutePattern(id: item.id, headsign: newHeadSign, name: item.name, patternGeometry: item.patternGeometry, stops: item.stops)
                            newRoutePatterns.append(newPattern)
                        } else {
                            let newPattern = RoutePattern(id: item.id, headsign: headsign, name: item.name, patternGeometry: item.patternGeometry, stops: item.stops)
                            newRoutePatterns.append(newPattern)
                        }
                    }
                } else {
                    let newPattern = RoutePattern(id: item.id, headsign: headsign, name: item.name, patternGeometry: item.patternGeometry, stops: item.stops)
                    newRoutePatterns.append(newPattern)
                }
            }
        }
        let newDuplicateRoutePatterns = self.findDuplicatesDirectionTitle(routePatterns: newRoutePatterns)
        var finalItems: [RoutePattern?] = []
        if newDuplicateRoutePatterns.isEmpty {
            finalItems = newRoutePatterns
        } else {
            for duplicate in newDuplicateRoutePatterns {
                var filteredItems: [RoutePattern?] = []
                for item in newRoutePatterns {
                    if let item = item, let headsign = item.headsign {
                        if headsign == duplicate {
                            filteredItems.append(item)
                        }
                    }
                }
                var maxPattern: RoutePattern? = nil
                for item in filteredItems {
                    if let item = item, let geo = item.patternGeometry, let length = geo.length {
                        if let mMaxPattern = maxPattern, let maxGeo = mMaxPattern.patternGeometry, let maxLength = maxGeo.length {
                            if length > maxLength {
                                maxPattern = item
                            } else {
                                maxPattern = mMaxPattern
                            }
                        } else {
                            maxPattern = item
                        }
                    }
                }
                finalItems.append(maxPattern)
            }
            for item in newRoutePatterns {
                if let item = item, let headsign = item.headsign {
                    if !newDuplicateRoutePatterns.contains(headsign){
                        finalItems.append(item)
                    }
                }
            }
        }
        
        // Removing the ParenthesesAndContent from the headsign
        var returnItems: [RoutePattern?] = []
        for item in finalItems {
            if let item = item, let headsign = item.headsign {
                let newHeadSign = Helper.shared.removeParenthesesAndContent(from: headsign)
                let newPattern = RoutePattern(id: item.id, headsign: newHeadSign, name: item.name, patternGeometry: item.patternGeometry, stops: item.stops)
                returnItems.append(newPattern)
            } else {
                returnItems.append(item)
            }
        }
        
        // Adding the last stop to duplicate headsign with less amount of stops count
        let updatedItems = updateRoutes(routes: returnItems)
        

        return updatedItems
    }

    
    /// Update routes.
    /// - Parameters:
    ///   - routes: Parameter description
    /// - Returns: [RoutePattern?]
    func updateRoutes(routes: [RoutePattern?]) -> [RoutePattern?] {
        var result: [RoutePattern?] = []
        var headSignDict: [String: RoutePattern?] = [:]

        for route in routes {
            if let route = route, let headsign = route.headsign, let stops = route.stops {
                if let existingRoute = headSignDict[headsign], let existingRoute = existingRoute, let existingRouteHeadsign = existingRoute.headsign, let existingRouteStops = existingRoute.stops {
                    if stops.count < existingRouteStops.count {
                        var updatedHeadSign = headsign
                        if let lastStop = stops.last {
                            let stopName = lastStop.name
                            updatedHeadSign += " (\(stopName))"
                        }
                        headSignDict[updatedHeadSign] = RoutePattern(id: route.id, headsign: updatedHeadSign, name: route.name, patternGeometry: route.patternGeometry, stops: stops)
                        result.append(RoutePattern(id: route.id, headsign: updatedHeadSign, name: route.name, patternGeometry: route.patternGeometry, stops: stops))
                    } else {
                        var updatedHeadSign = existingRouteHeadsign
                        if let lastStop = existingRouteStops.last {
                            let stopName = lastStop.name
                            updatedHeadSign += " (\(stopName))"
                        }
                        headSignDict[updatedHeadSign] = RoutePattern(id: route.id, headsign: updatedHeadSign, name: route.name, patternGeometry: route.patternGeometry, stops: stops)
                        result.append(RoutePattern(id: route.id, headsign: updatedHeadSign, name: route.name, patternGeometry: route.patternGeometry, stops: stops))
                    }
                } else {
                    headSignDict[headsign] = route
                    result.append(route)
                }
            }
            
        }

        return result
    }
    

    /// Filter subsets from super set.
    /// - Parameters:
    ///   - routePattern: Parameter description
    /// - Returns: [RoutePattern?]
    func filterSubsetsFromSuperSet(routePattern: [RoutePattern?]) -> [RoutePattern?] {
        var removeableSets: [RoutePattern?] = []
        let sortedSets = routePattern.sorted(by: {$0?.stops?.count ?? 0 > $1?.stops?.count ?? 0})
        
        for prePattern in sortedSets {
            for postPattern in sortedSets {
                if let preStops = prePattern?.stops, let postStops = postPattern?.stops {
                    if prePattern?.id != postPattern?.id {
                        let set1 = Set(preStops)
                        let set2 = Set(postStops)
                        
                        if set1.isSubset(of: set2) {
                            if checkSeq(preSet: preStops, postSet: postStops) {
                                removeableSets.append(prePattern)
                            }
                        }
                    }
                }
            }
        }
        return removeableSets
        
    }

    /// Check seq.
    /// - Parameters:
    ///   - preSet: Parameter description
    ///   - postSet: Parameter description
    /// - Returns: Bool
    func checkSeq(preSet: [Stop]?, postSet: [Stop]?) -> Bool{
        let isValidSequence = false
        if let preSet = preSet, let postSet = postSet {
            if preSet.count > 0 && postSet.count > 0 {
                let firstElement = preSet[0]
                let lastElement = preSet[preSet.count-1]
                
                let firstIndex = postSet.firstIndex(of: firstElement) ?? 0
                let lastIndex = postSet.lastIndex(of: lastElement) ?? 0
                if firstIndex != lastIndex && firstIndex < lastIndex {
                    let filteredArray = Array(postSet[firstIndex...lastIndex])
                    return preSet == filteredArray
                }
            }
        }
        return isValidSequence
    }
    
    /// Sort direction data.
    /// - Parameters:
    ///   - geoData: Parameter description
    /// - Returns: [Geometry]
    func sortDirectionData(geoData: [Geometry]) -> [Geometry]{
        var names: [String] = []
        var largestGeoData : [Geometry] = []
        for item in geoData{
            let name = item.desc.slice(from: "to ", to: " (")
            if !names.contains(name ?? ""){
                names.append(name ?? "")
            }
        }
        for name in names{
            var tempGeoData : [Geometry] = []
            for item in geoData{
                let itemName = item.desc.slice(from: "to ", to: " (")
                if name == itemName{
                    tempGeoData.append(item)
                }
            }
            let maxValue = tempGeoData.max { item1, item2 in
                item1.geometry!.length < item2.geometry!.length
            }
            largestGeoData.append(maxValue!)
        }
        return largestGeoData
        
        
    }
    
    /// Get direction stops.
    /// - Parameters:
    ///   - geometry: Parameter description
    /// Retrieves direction stops.
    public func getDirectionStops(geometry: Geometry) {
        self.isLoading = true
        self.pubDirectionStops.removeAll()
        if let annotations = MapManager.shared.mapView.annotations{
            MapManager.shared.mapView.removeAnnotations(annotations)
        }
        if let patternsData = self.pubPatternsData {
            for item in patternsData {
                if let item = item {
                    if item.id == geometry.id{
                        if let stops = item.stops {
                            self.pubDirectionStops = stops
                            MapManager.shared.renderRouteDirectionStopMarker(stops: self.pubDirectionStops)
                            self.isLoading = false
                        }
                    }
                }
            }
        }
    }
    
    /// Find route info.
    /// - Parameters:
    ///   - route: Parameter description
    /// - Returns: (UIColor, Mode)
    private func findRouteInfo(route: TransitRoute) -> (UIColor, Mode) {
        let defaultColor = "000000"
        let defaultMode = Mode.bus
        var colorCode = route.color ?? defaultColor
        var mode = route.mode ?? defaultMode
        if route.color == nil || route.mode == nil {
            let routeItems = RouteViewerModel.shared.pubRouteItems
            for item in routeItems {
                if item.route.id == route.id {
                    colorCode = item.route.color ?? defaultColor
                    mode = item.route.mode ?? defaultMode
                    break
                }
            }
        }
        return (UIColor(hex: "#\(colorCode)FF") ?? UIColor.black, mode)
    }
    
    /// Show geo route on map.
    /// - Parameters:
    ///   - geoPoints: Parameter description
    ///   - route: Parameter description
    func showGeoRouteOnMap(geoPoints: String, route: TransitRoute) {
        let (routeColor, mode) = findRouteInfo(route: route)
        guard let decodedCoordinates = Polyline(encodedPolyline: geoPoints).coordinates else { return }
        MapManager.shared.mapSize = .half
        let routeSegment = RouteSegment(routeType: mode, routeColor: routeColor, coorindates: decodedCoordinates)
        MapManager.shared.routePlotItems = RoutePlotItems(segments: [routeSegment])
        if let routePlot = MapManager.shared.routePlotItems{
            MapManager.shared.plotRoute(segments: routePlot.segments)
        }
        
        if !(StopViewerViewModel.shared.pubIsShowingStopViewer) {
            var viewArea = ViewArea(topRight: CGPoint(x:UIScreen.main.bounds.width,y:0), bottomLeft: CGPoint(x:0, y:Helper.shared.getDeafultViewHeight(heightPosition: bottomSlideBarModel.pubBottomSlideBarPosition)))
            let edgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 20)
            if BottomSlideBarViewModel.shared.isSliderFullOpen{
                viewArea = ViewArea(topRight: CGPoint(x:UIScreen.main.bounds.width,y:0), bottomLeft: CGPoint(x:0, y:Helper.shared.getDeafultViewHeight(heightPosition: .top)))
            }
            
            MapManager.shared.setCenterArea(viewArea: viewArea, mapViewHeight: Helper.shared.getDefaultMapViewHeight(), mapViewWidth: UIScreen.main.bounds.width,edgeInset: edgeInsets)
        }
        
    }
    
    /// Show route on map.
    /// - Parameters:
    ///   - route: Parameter description
    /// Shows route on map.
    func showRouteOnMap(route: TransitRoute) {
        var geometryPoints = pubGeometry?[0].geometry?.points
        if let geometries = pubGeometry, let patternId = route.patternId {
            for geo in geometries {
                if geo.id == patternId {
                    geometryPoints = geo.geometry?.points
                    break
                }
            }
        }
        
        let (routeColor, mode) = findRouteInfo(route: route)
        guard let routePath = geometryPoints,
              let decodedCoordinates = Polyline(encodedPolyline: routePath).coordinates else {
            return
        }
        
        MapManager.shared.mapSize = .half
        let routeSegment = RouteSegment(routeType: mode, routeColor: routeColor, coorindates: decodedCoordinates)
        MapManager.shared.routePlotItems = RoutePlotItems(segments: [routeSegment])
        if let routePlot = MapManager.shared.routePlotItems{
            MapManager.shared.plotRoute(segments: routePlot.segments)
        }
        
        if !(StopViewerViewModel.shared.pubIsShowingStopViewer) {
            var viewArea = ViewArea(topRight: CGPoint(x:UIScreen.main.bounds.width,y:0), bottomLeft: CGPoint(x:0, y:Helper.shared.getDeafultViewHeight(heightPosition: bottomSlideBarModel.pubBottomSlideBarPosition)))
            var edgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            if BottomSlideBarViewModel.shared.isSliderFullOpen{
                viewArea = ViewArea(topRight: CGPoint(x:UIScreen.main.bounds.width,y:0), bottomLeft: CGPoint(x:0, y:Helper.shared.getDeafultViewHeight(heightPosition: .top)))
                edgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 20)
            }
            
            MapManager.shared.setCenterArea(viewArea: viewArea, mapViewHeight: Helper.shared.getDefaultMapViewHeight(), mapViewWidth: UIScreen.main.bounds.width,edgeInset: edgeInsets)
        }
        
    }
    
    /// Show route direction on map.
    /// - Parameters:
    ///   - geoData: Parameter description
    ///   - routeColor: Parameter description
    ///   - mode: Parameter description
    func showRouteDirectionOnMap(geoData: LegGeometry, routeColor: String, mode: Mode){
        let geometryPoints = geoData.points
        guard let decodedCoordinates = Polyline(encodedPolyline: geometryPoints).coordinates else {return}
        
        MapManager.shared.mapSize = .half
        var polylineColor = UIColor.blueBackground
        if let color = UIColor(hex: "#\(routeColor)FF"){
            polylineColor = color
        }
        let routeSegment = RouteSegment(routeType: mode, routeColor: polylineColor, coorindates: decodedCoordinates)
        MapManager.shared.routePlotItems = RoutePlotItems(segments: [routeSegment])
        if let routePlot = MapManager.shared.routePlotItems{
            MapManager.shared.plotRoute(segments: routePlot.segments)
        }
        
        if !(StopViewerViewModel.shared.pubIsShowingStopViewer) {
            var viewArea = ViewArea(topRight: CGPoint(x:UIScreen.main.bounds.width,y:0), bottomLeft: CGPoint(x:0, y:Helper.shared.getDeafultViewHeight(heightPosition: bottomSlideBarModel.pubBottomSlideBarPosition)))
            var edgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            if BottomSlideBarViewModel.shared.isSliderFullOpen{
                viewArea = ViewArea(topRight: CGPoint(x:UIScreen.main.bounds.width,y:0), bottomLeft: CGPoint(x:0, y:Helper.shared.getDeafultViewHeight(heightPosition: .top)))
                edgeInsets = UIEdgeInsets(top: 20, left: 20, bottom: 0, right: 20)
            }
            MapManager.shared.setCenterArea(viewArea: viewArea, mapViewHeight: Helper.shared.getDefaultMapViewHeight(), mapViewWidth: UIScreen.main.bounds.width,edgeInset: edgeInsets)
        }
    }
    
    /// Get realtime bus data.
    /// - Parameters:
    ///   - route: Parameter description
    ///   - pattern: Parameter description
    func getRealtimeBusData(route: TransitRoute, pattern: String? = "") {
            
            if currentRoute != route {
                stopRealtimeBusUpdates()
                currentRoute = route
            }
            fetchBusData(route: route, pattern: pattern)

            // Start a timer that runs every 30 seconds
        busUpdateTimer = Timer.scheduledTimer(withTimeInterval: self.realTimeBusInfoRefreshInterval, repeats: true) { [weak self] _ in
                if self?.currentRoute != nil {
                    self?.fetchBusData(route: route, pattern: pattern)
                }
            }
        }
    /// Fetch bus data.
    /// - Parameters:
    ///   - route: Parameter description
    ///   - pattern: Parameter description
    /// Fetches bus data.
    private func fetchBusData(route: TransitRoute, pattern: String?) {
            let errorMessage = "No vehicle locations found. Please try again later.".localized()
        OTPLog.log(level: .info, info: "Real Time Bus Update for \(route.id)")
            busInfoProvider.retrieveRealTimeBusDataUsingGraphQL(route: route) { success, busData, error in
                if success, let busesData = busData {
                    DispatchQueue.main.async {
                        if !busesData.isEmpty {
                            let filteredData = pattern != nil ? busesData.filter { $0.patternId == pattern } : busesData
                            MapManager.shared.showRealtimeBus(busData: filteredData, pattern: pattern ?? "")
                        }
                    }
                } else {
                    UIAccessibility.post(notification: .announcement, argument: errorMessage)
                }
            }
        }

        // Function to stop the timer when leaving the view
        /// Stops realtime bus updates.
        func stopRealtimeBusUpdates() {
            OTPLog.log(level: .info, info: "Real Time Bus Updates has been Stopped")
            busUpdateTimer?.invalidate()
            busUpdateTimer = nil
            currentRoute = nil
        }
    
}
