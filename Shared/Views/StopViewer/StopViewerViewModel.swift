//
//  StopViewerViewModel.swift
//

import SwiftUI
import Mapbox
import Combine

enum StopMarkerType {
    case tripDetail, route, map, stopViewer
}

// MARK: - RequestStopTimes
struct RequestStopTimes: Codable {
    let query: String
    let variables: StopTimeVariables
}

// MARK: - StopTimeVariables
struct StopTimeVariables: Codable {
    let stopId: String
}

// MARK: - RequestStopSchedules
struct RequestStopSchedules: Codable {
    let query: String
    let variables: StopScheduleVariables
}

// MARK: - StopScheduleVariables
struct StopScheduleVariables: Codable {
    let serviceDay: Int
    let stopId: String
}

// MARK: - RequestShorterStopTimesQueryForOperators
struct RequestShorterStopTimesQueryForOperators: Codable {
    let query: String
    let variables: ShorterStopTimesQueryForOperators
}

// MARK: - ShorterStopTimesQueryForOperators
struct ShorterStopTimesQueryForOperators: Codable {
    let stopId: String
}


class StopViewerViewModel: ObservableObject, StopsService {
    @ObservedObject var mapManager = MapManager.shared
    @Published var zoomLevel = Double(BrandConfig.shared.zoom_level)
    @Published var itinerary: OTPItinerary? = nil
    @Published var itineraryStop: OTPLeg? = nil
    @Published var pubIsShowingStopViewer = false
    @Published var pubKeepShowingStopViewer = false
    @Published var stop: Stop? = nil
    @Published var isLoading: Bool = false
    @Published var showAlert = false
    @Published var isAutoRefresh = true
    @Published var lastStopRefresh = Date()
    @Published var scheduleData: [GraphQLStopViewerModel] = []
    @Published var pubDate = SearchManager.shared.dateSettings.departAt {
        didSet{
            getGraphQLStopTimes()
        }
    }
    @Published var pubScheduleSelectedDate = SearchManager.shared.dateSettings.departAt{
        didSet{
            pubDate = pubScheduleSelectedDate
            getGraphQLStopSchedules()
        }
    }
    @Published var graphQLDepartItems = [GraphQLDepartItem]()
    @Published var scrollToIndex: Int = -1
    
    @Published var scheduleTimes: [StopScheduleItem] = []
    @Published var isSchedulesLoading = false
    @Published var pubSelectedStopMode: SearchMode? = nil
    @Published var pubStopViewerOrigin: StopMarkerType? = .map
    @Published var pubAgencyIcons: [UIImage?] = []
    @Published var pubSelectedDepartItem: GraphQLDepartItem?
    var didChange = PassthroughSubject<Int,Never>()
    var data: [StopViewerModel]? = nil
    /// Selected stop.
    /// - Parameters:
    ///   - Stop?: Parameter description
    var selectedStop: Stop? {

        if let stop = stop {
            return stop
        } else if let from = itineraryStop?.from, let stop = from.stop, let gtfsID = stop.gtfsID{
            let returnStop = Stop(id: gtfsID, code: stop.code, name: from.name ?? "", lat: from.lat ?? 0, lon: from.lon ?? 0, stoptimesWithoutPatterns: [])
            return returnStop
        } else{
            return nil
        }
    }
    
    /// Stop id.
    /// - Parameters:
    ///   - String?: Parameter description
    var stopId: String? {
        var stopId: String? = stop?.id
        if stopId == nil {
            stopId = itineraryStop?.from?.stop?.gtfsID
        }
        return stopId
    }
    
    var autoRefreshTimer: Timer? = nil
    
    /// Shared instance to hold the value.
    static var shared: StopViewerViewModel = {
        let instance = StopViewerViewModel()
        let refresh = instance.isAutoRefresh
        instance.autoRefresh(isEnabled: refresh)
        return instance
    }()
    
    private var cancellableSet = Set<AnyCancellable>()
    var service: APIServiceProtocol = APIService()
    var errorMessage: String = ""
    
    /// Auto refresh.
    /// - Parameters:
    ///   - isEnabled: Parameter description
    func autoRefresh(isEnabled: Bool){
        if let timer = autoRefreshTimer {
            timer.invalidate()
            self.autoRefreshTimer = nil
        }
    }
    
    /// Cancel all stops requests
    /// Cancels all stops requests.
    func cancelAllStopsRequests(){
        if let timer = autoRefreshTimer {
            timer.invalidate()
            self.autoRefreshTimer = nil
        }
        cancellableSet.removeAll()
    }
    
    /// Get scroll to index
    /// Retrieves scroll to index.
    private func getScrollToIndex() {
        var scrollToIndex = -1
        var scheduleTimeData = [GraphQLStopTime]()
            for item in scheduleData {
                for timeItem in item.times{
                    scheduleTimeData.append(timeItem)
                }
            }
        scheduleTimeData = scheduleTimeData.sorted(by: { $0.departureDate < $1.departureDate })
        for index in 0..<scheduleTimeData.count{
            if scrollToIndex == -1{
                let time = scheduleTimeData[index].departureDate
                let currentTime = Date()
                if time > currentTime{
                    scrollToIndex = index
                    self.didChange.send(index)
                    DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            StopViewerViewModel.shared.scrollToIndex = index
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now()+1.5) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                StopViewerViewModel.shared.scrollToIndex = -1
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// Get last stop refresh time
    /// - Returns: String
    /// Retrieves last stop refresh time.
    func getLastStopRefreshTime() -> String{
        return Date().timeForStopViewer()
    }
    
    
    /// Get service day
    /// - Returns: TimeInterval
    /// Retrieves service day.
    func getServiceDay() -> TimeInterval{
        // Get the current date
        var currentDate = Date()
        if let selectedDate = pubScheduleSelectedDate {
            currentDate = selectedDate
        }
        var returnTimeInterval = currentDate.timeIntervalSince1970

        // Get the current calendar and timezone
        let calendar = Calendar.current
        // Using PDT timezone
        let timeZone = TimeZone(identifier: "America/Los_Angeles")!

        // Extract the year, month, and day components from the current date
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: currentDate)

        // Create date components for 3:30 AM
        var newDateComponents = DateComponents()
        newDateComponents.year = dateComponents.year
        newDateComponents.month = dateComponents.month
        newDateComponents.day = dateComponents.day
        newDateComponents.hour = 3
        newDateComponents.minute = 30
        newDateComponents.second = 0
        newDateComponents.timeZone = timeZone

        // Generate the new date
        if let newDate = calendar.date(from: newDateComponents) {
            // Convert the date to a time interval
            returnTimeInterval = newDate.timeIntervalSince1970
            OTPLog.log(level: .info, info: "TimeInterval: \(returnTimeInterval)")
        } else {
            OTPLog.log(level: .warning, info: "Failed to create the date.")
        }
        
        return returnTimeInterval
    }
    
    /// Get graph q l stop schedules
    /// Retrieves graph ql stop schedules.
    func getGraphQLStopSchedules() {
        scheduleData.removeAll()
        scheduleTimes.removeAll()
        guard let stopID = stopId else { return }
        self.isLoading = true
        
        let api = OTPAPIRequest()
        let requestQuery = GraphQLQueries.shared.graphQLStopSchedules
        let servieDay = getServiceDay()
        
        let requestStopTime = RequestStopSchedules(query: requestQuery, variables: StopScheduleVariables(serviceDay: Int(servieDay), stopId: stopID))
        
        var jsonKeyPair : [String : Any]?
        do{
            let jsonData = try JSONEncoder().encode(requestStopTime)
            if let jsonKey = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                jsonKeyPair = jsonKey
            }
        }catch{
            OTPLog.log(level: .error, info: "can not convert the parameters to the proper body data.\(requestStopTime)")
        }
        
        api.request(method: .post, path: BrandConfig.shared.graphQL_base_url, params: jsonKeyPair, headers: [:], format: .JSON) { [self] data, error, response in
            
            guard let data = data else {
                OTPLog.log(level:.info, info:"cannot receive the stop times response")
                return
            }
            
            if let err = error {
                OTPLog.log(level:.warning, info:"response from server for stop times is failed, \(err.localizedDescription)")
                guard let _ = DataHelper.object(data) as? [String: Any] else {
                    OTPLog.log(level:.warning, info:"response from server for stop times is failed, invalid error json data")
                    return
                }
                return
            }
            
            do{
                if let jsonData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let data = jsonData["data"] as? [String : Any]{
                        if let stop = data["stop"] as? [String : Any] {
                            
                            if let stopTimes = stop["stoptimesForPatterns"] as? [[String: Any]] {
                                if let stopTimesData = try? JSONSerialization.data(withJSONObject:stopTimes){
                                    let departureData = try JSONDecoder().decode([GraphQLStopViewerModel].self, from: stopTimesData)
                                    DispatchQueue.main.async { [self] in
                                        scheduleData = departureData
                                        loadNextDataChunk()
                                        isLoading = false
                                    }
                                }
                            }
                        }
                    } else {
                        OTPLog.log(level:.error, info: "can not decode the data, \(error)")
                    }
                }
            } catch {
                OTPLog.log(level:.error, info: "can not decode the data, \(error.localizedDescription)")
            }
        }
    }
    
    /// Get graph q l stop times
    /// Retrieves graph ql stop times.
    func getGraphQLStopTimes() {
        let api = OTPAPIRequest()
        let requestQuery = GraphQLQueries.shared.graphQLStopTimes
        guard let stopID = stopId else { return }
        
        let requestStopTime = RequestStopTimes(query: requestQuery, variables: StopTimeVariables(stopId: stopID))
        
        var jsonKeyPair : [String : Any]?
        do{
            let jsonData = try JSONEncoder().encode(requestStopTime)
            if let jsonKey = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                jsonKeyPair = jsonKey
            }
        }catch{
            OTPLog.log(level: .error, info: "can not convert the parameters to the proper body data.\(requestStopTime)")
        }
        
        api.request(method: .post, path: BrandConfig.shared.graphQL_base_url, params: jsonKeyPair, headers: [:], format: .JSON) { [self] data, error, response in
            
            guard let data = data else {
                OTPLog.log(level:.info, info:"cannot receive the stop times response")
                return
            }
            
            if let err = error {
                OTPLog.log(level:.warning, info:"response from server for stop times is failed, \(err.localizedDescription)")
                guard let _ = DataHelper.object(data) as? [String: Any] else {
                    OTPLog.log(level:.warning, info:"response from server for stop times is failed, invalid error json data")
                    return
                }
                return
            }
            
            do{
                if let jsonData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let data = jsonData["data"] as? [String : Any]{
                        if let stop = data["stop"] as? [String : Any] {
                            if let routes = stop["routes"] as? [[String: Any]] {
                                if let routeData = try? JSONSerialization.data(withJSONObject:routes){
                                    let routeData = try JSONDecoder().decode([TransitRoute].self, from: routeData)
                                    if !routeData.isEmpty {
                                        let routeItem = routeData[0]
                                        let routeId = routeItem.id
                                        let routesList = RouteViewerModel.shared.originRouteItemsSet
                                        for item in routesList {
                                            if item.route.id == routeId {
                                                DispatchQueue.main.async {
                                                    self.pubSelectedStopMode = item.route.searchMode
                                                    self.pubStopViewerOrigin = .map
                                                    self.addStopMarker()
                                                }
                                            }
                                        }
                                    }
                                }
                                
                            }
                            
                            if let stopTimes = stop["stoptimesForPatterns"] as? [[String: Any]] {
                                if let stopTimesData = try? JSONSerialization.data(withJSONObject:stopTimes){
                                    let departureData = try JSONDecoder().decode([GraphQLStopViewerModel].self, from: stopTimesData)
                                    DispatchQueue.main.async { [self] in
                                        graphQLDepartItems = processDepartItemsV2(departureData)
                                        self.iconForAgencies()
                                    }
                                }
                            }
                        }
                    } else {
                        OTPLog.log(level:.error, info: "can not decode the data, \(String(describing: error))")
                    }
                }
            } catch {
                OTPLog.log(level:.error, info: "can not decode the data, \(error.localizedDescription)")
            }
        }
    }
    
    private func processDepartItemsV2(_ data: [GraphQLStopViewerModel]) -> [GraphQLDepartItem] {
        var items = [GraphQLDepartItem]()
        var departItems = [GraphQLDepartItem]()
        var currentDepartTime:[GraphQLDepartureItem] = []
        
        /// Is original expanded.
        /// - Parameters:
        ///   - _: Parameter description
        /// - Returns: Bool
        func isOriginalExpanded(_ element: GraphQLStopViewerModel)->Bool{
            let currentItems = self.graphQLDepartItems
            for item in currentItems {
                if item.pattern.headsign == element.pattern.headsign{
                    return item.isExpanded
                }
            }
            return false
        }
        
        for element in data {
            
            for departTime in element.times{
                currentDepartTime.append(GraphQLDepartureItem(time: TimeInterval(departTime.scheduledDeparture), item: departTime))
            }
            
            if !currentDepartTime.isEmpty {
                let newDepartItem = GraphQLDepartItem(pattern: element.pattern, departTimes: currentDepartTime, isExpanded: isOriginalExpanded(element))
                items.append(newDepartItem)
                currentDepartTime.removeAll()
            }
             
        }
        
        // sort the time in each depart item
        var sortedDepartItems = [GraphQLDepartItem]()
        let now = NSDate()
        for item in items {
            var dts = [GraphQLDepartureItem]()
            dts = item.departTimes.sorted(by: { pre, nxt in
                let preTime = pre.item.realtimeDeparture + Int(pre.item.serviceDay) - Int(now.timeIntervalSince1970)
                let nxtTime = nxt.item.realtimeDeparture + Int(nxt.item.serviceDay) - Int(now.timeIntervalSince1970)
                
                return preTime < nxtTime
            })
            let sortedItem = GraphQLDepartItem(pattern: item.pattern, departTimes: dts)
            sortedDepartItems.append(sortedItem)
        }
        let newSortedArray = sortedDepartItems.sorted { pre, nxt in
            let preSecondsUntilDeparture = pre.departTimes[0].item.realtimeDeparture + Int(pre.departTimes[0].item.serviceDay) - Int(now.timeIntervalSince1970)
            let nxtSecondsUntilDeparture = nxt.departTimes[0].item.realtimeDeparture + Int(nxt.departTimes[0].item.serviceDay) - Int(now.timeIntervalSince1970)
                                                                                                                                
            return preSecondsUntilDeparture < nxtSecondsUntilDeparture
        }
        
        let unionDepartItems = graphQLUnionDepartureStops(newSortedArray)
        
        sortedDepartItems = unionDepartItems.sorted(by: { pre, post in
            let preShortTime = pre.departTimes.map({$0.item.realtimeDeparture + Int($0.item.serviceDay) - Int(now.timeIntervalSince1970)})
            
            let postShortTime = post.departTimes.map({$0.item.realtimeDeparture + Int($0.item.serviceDay) - Int(now.timeIntervalSince1970)})
            
            
            
            return Helper.shared.findSmallestElement(in: preShortTime) < Helper.shared.findSmallestElement(in: postShortTime)
        })
        
        // MARK: To keep selected depart item expanded when data refreshes.
        var returnItems: [GraphQLDepartItem] = []
        for item in sortedDepartItems {
            let newitem = GraphQLDepartItem(pattern: item.pattern, departTimes: item.departTimes, isExpanded: StopViewerViewModel.shared.pubSelectedDepartItem?.pattern == item.pattern)
            returnItems.append(newitem)
        }
        
        return returnItems
    }
    
    private func graphQLUnionDepartureStops(_ items: [GraphQLDepartItem]) -> [GraphQLDepartItem] {

        var mergedItems: [GraphQLDepartItem] = []
        var groupedItems: [String: GraphQLDepartItem] = [:]
        // MARK: find duplicated items and merge departTimes in one GraphQLDepartItem
        for item in items {
            var key = ""
            if let headSign = item.pattern.headsign {
                key = headSign
            } else if let desc = item.pattern.desc {
                key = desc
            } else {
                key = "\(item.pattern.route.shortName ?? "")-\(item.pattern.route.longName ?? "")-\(item.pattern.headsign)"
            }
            
            if var existingItem = groupedItems[key] {
                // MARK: Merge departTimes
                existingItem.departTimes.append(contentsOf: item.departTimes)
                groupedItems[key] = existingItem
            } else {
                // MARK: Add new item
                groupedItems[key] = item
            }
        }
        
        // MARK: Convert grouped items to an array
        mergedItems = groupedItems.values.map { item in
            var mergedItem = item
            mergedItem.departTimes = mergedItem.departTimes
                .sorted(by: {$0.item.realtimeDeparture + Int($0.item.serviceDay) - Int(Date.now.timeIntervalSince1970) < $1.item.realtimeDeparture + Int($1.item.serviceDay) - Int(Date.now.timeIntervalSince1970)}) // Sort departTimes by time
                .prefix(3) // Limit to 3 if count > 3
                .map { $0 } // Convert prefix result back to array
            return mergedItem
        }
        
        return mergedItems
    }
    
    
    private func graphQLUniqueDepartureStopsV2(_ items: [GraphQLDepartItem]) -> [GraphQLDepartItem] {
        var departItems = [GraphQLDepartItem]()
        
        if !items.isEmpty {
            for index in 0..<items.count {
                if departItems.isEmpty {
                    departItems.append(items[index])
                } else {
                    var filteredHeadSigns: [String] = []
                    let headSignForItem = graphQLExtractHeadsignFromPattern(item: items[index])
                    for item in departItems {
                        let headSignForFilter = graphQLExtractHeadsignFromPattern(item: item)
                        filteredHeadSigns.append(headSignForFilter)
                    }
                    if !filteredHeadSigns.contains(headSignForItem) {
                        departItems.append(items[index])
                    }
                }
            }
        }
        return departItems
    }

    func graphQLExtractHeadsignFromPattern(item: GraphQLDepartItem) -> String {
        let routeShortName = item.pattern.route.shortName ?? ""
        var headsign = item.pattern.headsign ?? ""
        
        if let desc = item.pattern.headsign {
            headsign = desc.slice(from: "to", to: "(") ?? desc
        } else {
            if let desc = item.pattern.desc {
                headsign = desc.slice(from: "to", to: "(") ?? ""
            } else {
                headsign = "No headsign found"
            }
        }

        
        return "\(routeShortName) \(headsign)"
    }
    func loadNextDataChunk() {
        // Simulate loading data asynchronously with a delay
        isSchedulesLoading = true
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            let newDataChunk = self.generateNextDataChunk()
            DispatchQueue.main.async { [self] in
                scheduleTimes += newDataChunk
                isSchedulesLoading = false
            }
        }
    }
    
    func generateNextDataChunk() -> [StopScheduleItem] {
        // Simulate generating the next chunk of data
        let tempScheduleData = scheduleData
            let startIndex = scheduleTimes.count
            let endIndex = min(startIndex + 30, tempScheduleData.scheduleTimes.count) // Load 30 items at a time, up to a maximum of data.count items
            var newDataChunk: [StopScheduleItem] = []
            if startIndex < endIndex {
                for i in startIndex..<endIndex {
                    if tempScheduleData.scheduleTimes.count > i {
                        newDataChunk.append(tempScheduleData.scheduleTimes[i])
                    }
                }
            }
            
            return newDataChunk
    }
    
    func addStopMarker() {
        if let stop = self.stop {
            let lat = stop.lat
            let lon = stop.lon
            let coordinates = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            mapManager.removeStopMarker()
            mapManager.addStopMarker(coordinates: coordinates)
            mapManager.centerCooridnateInDeepLevel(location: coordinates, withDelay: 0)
        }
    }
    
    func iconForAgencies(){
        let departItems = self.graphQLDepartItems
        let routes = RouteViewerModel.shared.pubRouteItems
        var agencyImages: [UIImage?] = []
        for item in departItems {
            let pattern = item.pattern
            let agency = pattern.route.agency
            let agencyName = agency.name
            var agencyImage: UIImage? = nil
            let mappedAgencyName = Helper.shared.mapAgencyNameAliase(agencyName: agencyName)
            if mappedAgencyName.count > 0 {
                agencyImage = RouteViewerModel.shared.agencyLogos[mappedAgencyName.lowercased()]
                agencyImages.append(agencyImage)
            }
        }
        let filteredImages = Helper.shared.removeTDuplicates(from: agencyImages)
        self.pubAgencyIcons = filteredImages
    }
}
