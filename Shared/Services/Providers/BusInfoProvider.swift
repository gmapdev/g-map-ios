//
//  BusInfoProvider.swift
//

import Foundation
import Combine
import SwiftUI

class BusInfoProvider: BaseProvider {
    
    /// Retrieve real time bus data using graph q l.
    /// - Parameters:
    ///   - route: Parameter description
    ///   - completion: Parameter description
    ///   - [RealTimeBus]?: Parameter description
    ///   - String?: Parameter description
    /// - Returns: Void))
    func retrieveRealTimeBusDataUsingGraphQL(route: TransitRoute, completion: @escaping ((Bool, [RealTimeBus]?, String?)->Void)){
        let api = OTPAPIRequest()
        let url = BrandConfig.shared.graphQL_base_url
        let requestQuery = GraphQLQueries.shared.vehiclePosition
        let routeId = route.id
        
        //MARK: - for requesting GraphQL Query from our APIManager, we need to pass Query and variable in key-value pair as paramaters
        let jsonKeyPair = [ "query" : "\(requestQuery)",
                            "variables" : [ "routeId" : "\(routeId)" ] ] as [String : Any]
        api.request(method: .post, path: url, params: jsonKeyPair, headers: [:], format: .JSON) { data, error, response in
            
            guard let data = data else {
                OTPLog.log(level:.info, info:"cannot receive the bus list response")
                completion(false, nil, nil)
                return
            }
            
            if let err = error {
                OTPLog.log(level:.warning, info:"response from server for bus list is failed, \(err.localizedDescription)")
                guard let _ = DataHelper.object(data) as? [String: Any] else {
                    OTPLog.log(level:.warning, info:"response from server for bus list is failed, invalid error json data")
                    completion(false, nil, error?.localizedDescription)
                    return
                }
                completion(false, nil, error?.localizedDescription)
                return
            }
            do{
                if let jsonData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    if let data = jsonData["data"] as? [String : Any]{
                        if let routeData = data["route"] as? [String : Any]{
                            if let patterns = routeData["patterns"] as? [[String : Any]]{
                                var busesData : [RealTimeBus] = []
                                for pattern in patterns{
                                    if let vehiclePositions = pattern["vehiclePositions"] as? [[String : Any]]{
                                        if !(vehiclePositions.count < 1) {
                                            for vehiclePosition in vehiclePositions{
                                                
                                                var patternId = ""
                                                if let trip = vehiclePosition["trip"] as? [String : Any]{
                                                    if let tripPattern = trip["pattern"] as? [String : Any],
                                                       let id = tripPattern["id"] as? String{
                                                        patternId = id
                                                    }
                                                }
                                                var vehicleId = ""
                                                if let vehicleID = vehiclePosition["vehicleId"] as? String{
                                                    vehicleId = vehicleID
                                                }
                                                
                                                var label = ""
                                                if let labelInfo = vehiclePosition["label"] as? String{
                                                    label = labelInfo
                                                }
                                                
                                                var lat = 0.0
                                                if let latitude = vehiclePosition["lat"] as? Double{
                                                    lat = latitude
                                                }
                                                var lon = 0.0
                                                if let longitude = vehiclePosition["lon"] as? Double{
                                                    lon = longitude
                                                }
                                                var speed = 0.0
                                                if let speedInfo = vehiclePosition["speed"] as? Double{
                                                    speed = speedInfo
                                                }
                                                var heading = 0.0
                                                if let headingInfo = vehiclePosition["heading"] as? Double{
                                                    heading = headingInfo
                                                }
                                                var seconds = 0.0
                                                if let secondsInfo = vehiclePosition["lastUpdated"] as? Double{
                                                    seconds = secondsInfo
                                                }
                                                let item = RealTimeBus(vehicleId: vehicleId, label: label, lat: lat, lon: lon, speed: speed, heading: heading, seconds: seconds, patternId: patternId, mode: route.searchMode)
                                                busesData.append(item)
                                                
                                            }
                                        }
                                    }
                                }
                                if !(busesData.isEmpty){
                                    completion(true, busesData, nil)
                                }else{
                                    completion(false, nil, nil)
                                    return
                                }
                            }
                        }
                    }
                }
            } catch {
                OTPLog.log(level:.error, info: "can not decode the search modes, \(error.localizedDescription)")
                completion(false, nil, error.localizedDescription)
            }
        }
    }
    
    /// Retrieve real time bus data.
    /// - Parameters:
    ///   - stopId: Parameter description
    ///   - completion: Parameter description
    ///   - String?: Parameter description
    /// - Returns: Void))
    func retrieveRealTimeBusData(stopId: String, completion: @escaping (([RealTimeBus]?, String?)->Void)){

        let apiAccessProvider = APIAccessProvider()
        var requestURL = apiAccessProvider.baseURL + TripEndPoint.busInfo.url().endpoint
        requestURL = requestURL.replacingOccurrences(of: "{BUS_NUMBER}", with: "\(stopId)",
                          options: NSString.CompareOptions.literal, range:nil)
        let requestMethod = TripEndPoint.busInfo.url().method
        if let requestUrl = URL(string: requestURL) {
          var request = URLRequest(url: requestUrl)
          request.httpMethod = requestMethod
          let publisher:AnyPublisher<APIAccessResponse<[RealTimeBus]>, Error> = apiAccessProvider.run(request)
          publisher.sink(receiveCompletion: { result in
            switch result {
              case .failure(let error):
                OTPLog.log(level: .error, info: "failed to retrieve the trip information: \(error)")
              case .finished:
                OTPLog.log(level: .info, info: "Complete Sink")
                break
              }
            }) { (result) in
              if result.success {
                if let response = result.value {
                  completion(response, nil)
                }else{
                  completion(nil, "failed to parse the returned trip information")
                }
              }else{
                completion(nil, "failed to retreive the trip information for")
              }
          }
          .store(in: &anyCancellables)
        }
      }
}
