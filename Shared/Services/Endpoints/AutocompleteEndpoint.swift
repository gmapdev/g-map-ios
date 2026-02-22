//
//  AutocompleteEndpoint.swift
//

import Foundation
import CoreLocation

enum AutocompleteEndpoint {
    case locations(searchText: String, minCoordinate: Coordinate, maxCoordinate: Coordinate)
	case reverse(latitude: Double, longitude: Double)
}

extension AutocompleteEndpoint {
    /// Request.
    /// - Parameters:
    ///   - APIRequest: Parameter description
    var request: APIRequest {
        switch self {
        case .locations(let searchText, let minCoordinate, let maxCoordinate):
            if let userLocation = MapManager.shared.mapView.userLocation {
                if let location = userLocation.location{
                    return APIRequest(path: "/autocomplete",
                                      parameters: ["text": searchText,
                                                   "layers": "address,venue,street,intersection".percentEncoded(),
                                                   "boundary.rect.min_lat": String(minCoordinate.latitude),
                                                   "boundary.rect.min_lon": String(minCoordinate.longitude),
                                                   "boundary.rect.max_lat": String(maxCoordinate.latitude),
                                                   "boundary.rect.max_lon": String(maxCoordinate.longitude),
                                                   "focus.point.lat": String(location.coordinate.latitude),
                                                   "focus.point.lon": String(location.coordinate.longitude)],
                                      headers: RequestParams.headersJSON,
                                      baseURLString: BrandConfig.shared.autocomplete_url)
                }else{
                    return APIRequest(path: "/autocomplete",
                                      parameters: ["text": searchText,
                                                   "layers": "address,venue,street,intersection".percentEncoded(),
                                                   "boundary.rect.min_lat": String(minCoordinate.latitude),
                                                   "boundary.rect.min_lon": String(minCoordinate.longitude),
                                                   "boundary.rect.max_lat": String(maxCoordinate.latitude),
                                                   "boundary.rect.max_lon": String(maxCoordinate.longitude),
                                                   "focus.point.lat": "33.749",
                                                   "focus.point.lon": "-84.388"],
                                      headers: RequestParams.headersJSON,
                                      baseURLString: BrandConfig.shared.autocomplete_url)
                }
            }
            else{
                return APIRequest(path: "/autocomplete",
                                  parameters: ["text": searchText,
                                               "layers": "address,venue,street,intersection".percentEncoded(),
                                               "boundary.rect.min_lat": String(minCoordinate.latitude),
                                               "boundary.rect.min_lon": String(minCoordinate.longitude),
                                               "boundary.rect.max_lat": String(maxCoordinate.latitude),
                                               "boundary.rect.max_lon": String(maxCoordinate.longitude),
                                               "focus.point.lat": "33.749",
                                               "focus.point.lon": "-84.388"],
                                  headers: RequestParams.headersJSON,
                                  baseURLString: BrandConfig.shared.autocomplete_url)
            }
            
        case .reverse(let latitude, let longitude):
            return  APIRequest(path: "/reverse",
                                       method: .get,
                                       parameters: ["point.lat":"\(latitude)", "point.lon":"\(longitude)"],
                                       headers: RequestParams.headersJSON,
                                       baseURLString: BrandConfig.shared.autocomplete_url)
        }
    }
}
