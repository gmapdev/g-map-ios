//
//  ModeMappingProvider.swift
//

import Foundation


class ModeMappingProvider: BaseProvider {
    
    let bannedRouteURL =  FeatureConfig.shared.banned_route_list
    
    /// Fetch banned route list
    /// Fetches banned route list.
    func fetchBannedRouteList() {
        guard let url = URL(string: bannedRouteURL) else {
            return
        }
        OTPLog.log(level: .info, info: "this is banned route: \(url)")

        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                OTPLog.log(level: .error, info: "Error: \(error.localizedDescription)")
                return
            }

            if let data = data {
                do {
                    let decodedData = try JSONSerialization.jsonObject(with: data) as? [String: [String]]
                    DispatchQueue.main.async {
                        TripPlanningManager.shared.pubBannedRoutes = decodedData
                    }
                } catch {
                    OTPLog.log(level: .error, info: "Error decoding JSON: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
    
}
