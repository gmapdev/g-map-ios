//
//  RoutingErrorsProvider.swift
//

import Foundation
import Combine

enum RoutingErrorCode: String {
    case noTransitConnection = "NO_TRANSIT_CONNECTION"
    case noTransitConnectionInSearchWindow = "NO_TRANSIT_CONNECTION_IN_SEARCH_WINDOW"
    case outsideServicePeriod = "OUTSIDE_SERVICE_PERIOD"
    case systemError = "SYSTEM_ERROR"
    case locationNotFound = "LOCATION_NOT_FOUND"
    case noStopsInRange = "NO_STOPS_IN_RANGE"
    case oursideBounds = "OUTSIDE_BOUNDS"
}

struct RoutingErrors: Codable, Identifiable {
    let id = UUID()
    let errorCode: String
    let displayText: String
    let displaySubText: String
    
    enum CodingKeys: String, CodingKey {
        case errorCode, displayText, displaySubText
    }
}


class RoutingErrorsProvider: BaseProvider {
    
    let url = FeatureConfig.shared.search_error_list_mapping
    
    /// Fetch error mapping list
    /// Fetches error mapping list.
    func fetchErrorMappingList() {
        guard let url = URL(string: url) else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                OTPLog.log(level: .error, info: "Error: \(error.localizedDescription)")
                return
            }

            if let data = data {
                do {
                    let decodedData = try JSONDecoder().decode([RoutingErrors].self, from: data)
                    DispatchQueue.main.async {
                        TripPlanningManager.shared.routingErrors = decodedData
                    }
                } catch {
                    OTPLog.log(level: .error, info: "Error decoding JSON: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
}
