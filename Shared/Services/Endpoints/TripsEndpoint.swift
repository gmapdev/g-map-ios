//
//  TripsEndpoint.swift
//

import Foundation

enum TripsEndpoint {
    case tripDetails(String)
    case stops(String)
    case stopTimes(String)
}

extension TripsEndpoint {
    /// Request.
    /// - Parameters:
    ///   - APIRequest: Parameter description
    var request: APIRequest {
        switch self {
        case .tripDetails(let tripId):
            return APIRequest(path: "/otp/routers/default/index/trips/" + tripId,
                              headers: RequestParams.headersJSON,
                              baseURLString: BrandConfig.shared.base_url)
        case .stops(let tripId):
            return APIRequest(path: "/otp/routers/default/index/trips/" + tripId + "/stops",
                              headers: RequestParams.headersJSON,
                              baseURLString: BrandConfig.shared.base_url)
        case .stopTimes(let tripId):
            return APIRequest(path: "/otp/routers/default/index/trips/" + tripId + "/stoptimes",
                              headers: RequestParams.headersJSON,
                              baseURLString: BrandConfig.shared.base_url)
        }
    }
}
