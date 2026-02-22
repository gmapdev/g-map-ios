//
//  RouteEndpoint.swift
//

import Foundation

enum RouteEndpoint {
    case routes
    case routeDetails(String)
    case routePattern(String)
    case routeGeometry(String)
    case directionStops(String)
}

extension RouteEndpoint {
    /// Request.
    /// - Parameters:
    ///   - APIRequest: Parameter description
    var request: APIRequest {
        switch self {
        case .routes:
            return APIRequest(path: "/index/routes/",
                              headers: RequestParams.headersJSON,
							  baseURLString: BrandConfig.shared.base_url)
        case .routeDetails(let routeId):
            return APIRequest(path: "/index/routes/" + routeId,
                              headers: RequestParams.headersJSON,
                              baseURLString: BrandConfig.shared.base_url)
        case .routeGeometry(let patternId):
            return APIRequest(path: "/index/patterns/" + patternId + "/geometry",
                              headers: RequestParams.headersJSON,
                              baseURLString: BrandConfig.shared.base_url)
            
        case .directionStops(let routeId):
            return APIRequest(path: "/index/patterns/" + routeId + "/stops",
                              headers: RequestParams.headersJSON,
                              baseURLString: BrandConfig.shared.base_url)
        case .routePattern(let routeId):
            return APIRequest(path: "/index/routes/" + routeId + "/patterns",
                              headers: RequestParams.headersJSON,
                              baseURLString: BrandConfig.shared.base_url)
        }
    }
}
