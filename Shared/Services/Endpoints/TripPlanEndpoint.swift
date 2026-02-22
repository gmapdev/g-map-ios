//
//  TripPlanEndpoint.swift
//

import Foundation

enum TripPlanEndpoint {
    
    case stopViewer(stopId: String,
                    from: Autocomplete.Feature,
                    to: Autocomplete.Feature,
                    modes: [Mode],
                    criterias: Criterias,
                    dateSettings: DateSettings)
}

extension TripPlanEndpoint {
    /// Request.
    /// - Parameters:
    ///   - APIRequest: Parameter description
    var request: APIRequest {
        switch self {
        case let .stopViewer(stopId, from, to, modes, criterias, dateSettings):
            let date = dateSettings.date
            let params = ["fromPlace": from.tripRequestParam.percentEncoded(),
                          "toPlace": to.tripRequestParam.percentEncoded(),
                          "optimize": criterias.optimiseParam,
                          "walkSpeed": String(criterias.walkSpeed),
                          "maxWalkDistance": criterias.distanceParam,
                          "showIntermediateStops": String(true),
                          "mode": modes.modesString.percentEncoded(),
                          "arriveBy": String(dateSettings.isArriveBy),
                          "date": date.dateParam,
                          "time": date.timeParam.percentEncoded(),
                          "numItineraries": String(3),
                          "otherThanPreferredRoutesPenalty": String(900),
                          "ignoreRealtimeUpdates": String(true),
                          "companies": "",
                          "bannedRoutes": "",
                          "preferredRoutes": ""]
            return APIRequest(path: "/plan",
                              parameters: params,
                              headers: RequestParams.headersJSON,
							  baseURLString: BrandConfig.shared.base_url + "/\(stopId)")
		}
    }
}

extension Array where Element == Mode {
    /// Modes string.
    /// - Parameters:
    ///   - String: Parameter description
    var modesString: String {
        self.map {$0.rawValue}.joined(separator: ",")
    }
}

extension DateSettings {
    /// Date.
    /// - Parameters:
    ///   - Date: Parameter description
    var date: Date {
        if let arriveBy = arriveBy {
            return arriveBy
        } else if let departAt = departAt {
            return departAt
        } else {
            return Date()
        }
    }
    
    /// Is arrive by.
    /// - Parameters:
    ///   - Bool: Parameter description
    var isArriveBy: Bool {
        return arriveBy != nil
    }
}

extension Criterias {
    /// Distance param.
    /// - Parameters:
    ///   - String: Parameter description
    var distanceParam: String {
        return String(maximumWalk.maxWalkInMeters)
    }
    
    /// Optimise param.
    /// - Parameters:
    ///   - String: Parameter description
    var optimiseParam: String {
		if self.optimize == "Speed" {
			return "QUICK"
		}
		return "TRANSFERS"
    }
    
    /// Optimize string
    /// - Returns: String
    /// Optimize string.
    func optimizeString() -> String {
        if self.optimize == "Speed" {
            return "QUICK"
        }
        return "TRANSFERS"
    }
    
    /// Walk speed trans
    /// - Returns: String
    /// Walk speed trans.
    func walkSpeedTrans() -> String {
        let msUnit: Float = 0.44704
        let result = String(format: "%.2f", Float(walkSpeed) * msUnit )
        return result
    }
}
