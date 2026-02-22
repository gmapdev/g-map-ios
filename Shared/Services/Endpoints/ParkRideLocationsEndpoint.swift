//
//  ParkRideLocationsEndpoint.swift
//

import Foundation

enum ParkRideLocationsEndpoint {
    case parkAndRides(maxTransitDistance: Double)
}

extension ParkRideLocationsEndpoint {
    /// Request.
    /// - Parameters:
    ///   - APIRequest: Parameter description
    var request: APIRequest {
        switch self {
        case .parkAndRides(let maxTransitDistance):
            return APIRequest(path: "/otp/routers/default/park_and_ride",
                              parameters: ["maxTransitDistance": String(maxTransitDistance)],
                              headers: RequestParams.headersJSON,
                              baseURLString: BrandConfig.shared.base_url)
        }
    }
}
