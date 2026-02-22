//
//  StopEndpoint.swift
//

import Foundation

enum StopEndpoint {
    case stopTimes(String, Int, Bool, TimeInterval, TimeInterval, Int)
    case stopSchedule(String, Int, Bool, TimeInterval, Date)
}

extension StopEndpoint {
    /// Request.
    /// - Parameters:
    ///   - APIRequest: Parameter description
    var request: APIRequest {
        switch self {
        case .stopTimes(let stopId,
                        let numberOfDepartures,
                        let showBlockIds,
                        let timeRange,
                        let startTime,
                        let nearbyRadius):
            return APIRequest(path: "/otp/routers/default/index/stops/" + stopId + "/stoptimes",
                              parameters: ["numberOfDepartures": String(numberOfDepartures),
                                           "showBlockIds": String(showBlockIds),
                                           "timeRange": String(Int(timeRange)),
                                           "startTime": String(Int(startTime)),
                                           "nearbyRadius": String(nearbyRadius)],
                              headers: RequestParams.headersJSON,
							  baseURLString: BrandConfig.shared.base_url)
        case .stopSchedule(let stopId,
                           let numberOfDepartures,
                           let showBlockIds,
                           let timeRange,
                           let date):
            return APIRequest(path: "/otp/routers/default/index/stops/" + stopId + "/stoptimes" + "/\(date.dateParam("yyyyMMdd"))",
                              parameters: ["numberOfDepartures": String(numberOfDepartures),
                                           "showBlockIds": String(showBlockIds),
                                           "timeRange": String(Int(timeRange))],
                              headers: RequestParams.headersJSON,
							  baseURLString: BrandConfig.shared.base_url)
        }
    }
}
