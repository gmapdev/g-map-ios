//
//  MapAnnotationsFeedProvider.swift
//

import Foundation

struct RentalVehicle: Codable {
    let id, vehicleID: String?
    let name: String?
    let allowPickupNow: Bool?
    let network: Network?
    let lon, lat: Double?
    let rentalUris: JSONNull?
    let operative: Bool?
    let vehicleType: VehicleType?
    
    enum CodingKeys: String, CodingKey {
        case id
        case vehicleID = "vehicleId"
        case name, allowPickupNow, network, lon, lat, rentalUris, operative, vehicleType
    }
}

struct VehicleType: Codable, Equatable {
    let formFactor: FormFactor?
    let propulsionType: String?
}
enum FormFactor: String, Codable {
    case bicycle = "BICYCLE"
    case scooter = "SCOOTER"
}
enum Network: String, Codable {
    case birdSeattleWashington = "bird-seattle-washington"
    case limeSeattle = "lime_seattle"
    case linkSeattle = "Link_Seattle"
}

class MapAnnotationsFeedProvider{
    
    var sharedVehiclesLocations : [RentalVehicle]?
    var stopsLocations : [Stop]?
    var agencyFeed : [AgencyFeed]?

    
    /// Shared.
    /// - Parameters:
    ///   - MapAnnotationsFeedProvider: Parameter description
    public static var shared: MapAnnotationsFeedProvider = {
        let mgr = MapAnnotationsFeedProvider()
        return mgr
    }()
    
    /// Get map stops.
    /// - Parameters:
    ///   - completion: Parameter description
    /// - Returns: Void))
    func getMapStops(completion:@escaping (([Stop]?)->Void)){
        let api = OTPAPIRequest()
        let requestQuery = GraphQLQueries.shared.mapStops
        
        let requestTripPlan = RequestMapStops(query: requestQuery)
        var jsonKeyPair : [String : Any]?
        do{
            let jsonData = try JSONEncoder().encode(requestTripPlan)
            if let jsonKey = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                jsonKeyPair = jsonKey
            }
        }catch{
            OTPLog.log(level: .error, info: "can not convert the parameters to the proper body data.\(requestTripPlan)")
        }
        api.request(method: .post, path: BrandConfig.shared.graphQL_base_url, params: jsonKeyPair, headers: [:], format: .JSON) { data, error, response in
            
            guard let data = data else {
                OTPLog.log(level:.info, info:"cannot receive the map stops response")
                return
            }
            
            if let err = error {
                OTPLog.log(level:.warning, info:"response from server for map stops is failed, \(err.localizedDescription)")
                guard let _ = DataHelper.object(data) as? [String: Any] else {
                    OTPLog.log(level:.warning, info:"response from server for map stops is failed, invalid error json data")
                    return
                }
                completion(nil)
            }
            
            do{
                if let jsonData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let data = jsonData["data"] as? [String : Any]{
                        if let stops = data["stops"] as? [[String: Any]]{
                            let stopsData = try JSONSerialization.data(withJSONObject: stops, options: [])
                            let stopList = try JSONDecoder().decode([Stop].self, from: stopsData)
                            
                            DispatchQueue.main.async {
                                var filteredStopList: [Stop] = []
                                if !stopList.isEmpty {
                                    filteredStopList = stopList.filter { stop in
                                        if let stopTimes = stop.stoptimesWithoutPatterns {
                                            return !stopTimes.isEmpty
                                        }
                                        return false
                                    }
                                }
                                self.stopsLocations = filteredStopList
                                completion(self.stopsLocations)
                            }
                        }
                        
                    } else {
                    }
                }
            } catch {
                OTPLog.log(level:.error, info: "can not decode the response, \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
    
    func getAgancyFeed(completion:@escaping (([AgencyFeed]?)->Void)){
        let api = OTPAPIRequest()
        let requestQuery = GraphQLQueries.shared.feedsQuery
        
        let requestTripPlan = RequestMapStops(query: requestQuery)
        var jsonKeyPair : [String : Any]?
        do{
            let jsonData = try JSONEncoder().encode(requestTripPlan)
            if let jsonKey = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                jsonKeyPair = jsonKey
            }
        }catch{
            OTPLog.log(level: .error, info: "can not convert the parameters to the proper body data.\(requestTripPlan)")
        }
        api.request(method: .post, path: BrandConfig.shared.graphQL_base_url, params: jsonKeyPair, headers: [:], format: .JSON) { data, error, response in
            
            guard let data = data else {
                OTPLog.log(level:.info, info:"cannot receive the Agancy Feed response")
                return
            }
            
            if let err = error {
                OTPLog.log(level:.warning, info:"response from server for Agancy Feed is failed, \(err.localizedDescription)")
                guard let _ = DataHelper.object(data) as? [String: Any] else {
                    OTPLog.log(level:.warning, info:"response from server for Agancy Feed is failed, invalid error json data")
                    return
                }
                completion(nil)
            }
            
            do{
                if let jsonData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let data = jsonData["data"] as? [String : Any]{
                        if let agency = data["feeds"] as? [[String: Any]]{
                            let agencyData = try JSONSerialization.data(withJSONObject: agency, options: [])
                            let agencyList = try JSONDecoder().decode([AgencyFeed].self, from: agencyData)
                            DispatchQueue.main.async {
                                self.agencyFeed = agencyList
                                completion(self.agencyFeed)
                            }
                        }
                    }
                }
            } catch {
                OTPLog.log(level:.error, info: "can not decode the response, \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
    
    /// Get rental vehicle locations.
    /// - Parameters:
    ///   - completion: Parameter description
    /// - Returns: Void))
    func getRentalVehicleLocations(completion:@escaping (([RentalVehicle]?)->Void)){
        
        let api = OTPAPIRequest()
        let requestQuery = GraphQLQueries.shared.sharedVehicleLocations
        let jsonKeyPair = [ "query" : "\(requestQuery)"] as [String : Any]
        
        api.request(method: .post, path: BrandConfig.shared.graphQL_base_url, params: jsonKeyPair, headers: [:], format: .JSON) { data, error, response in
            
            guard let data = data else {
                OTPLog.log(level:.info, info:"cannot receive the Rental Vehicle Locations response")
                return
            }
            
            if let err = error {
                OTPLog.log(level:.warning, info:"response from server for rental Locations list is failed, \(err.localizedDescription)")
                guard let _ = DataHelper.object(data) as? [String: Any] else {
                    OTPLog.log(level:.warning, info:"response from server for  rental Locations list is failed, invalid error json data")
                    return
                }
                completion(nil)
            }
            
            do{
                if let jsonData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let data = jsonData["data"] as? [String : Any]{
                        if let rentalVehicles = data["rentalVehicles"] as? [[String : Any]]{
                            if let locationData = try? JSONSerialization.data(withJSONObject: rentalVehicles){
                                let locations = try JSONDecoder().decode([RentalVehicle].self, from: locationData)
                                self.sharedVehiclesLocations = locations
                                completion(self.sharedVehiclesLocations)
                            }
                        }
                    }
                }
            }
            catch{
                OTPLog.log(level:.error, info: "can not decode the search modes, \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
}
