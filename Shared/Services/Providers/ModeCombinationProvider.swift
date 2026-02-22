//
//  ModeCombinationProvider.swift
//

import Foundation
import Combine

struct ModeCombination: Codable {
    var selectedModes: [String]
    var selectedSubModes: [String]
    var sentModeCombinations: [SentModeCombinations]?
}

struct SentModeCombinations: Codable {
    var modes: [SelectedMode]?
}

struct SelectedMode: Codable, Hashable, Equatable{
    var mode : String?
    var qualifier: String?
}


class ModeCombinationProvider: BaseProvider {
    
    let url = FeatureConfig.shared.route_mode_combinations_url
    
    /// Fetch mode combinations
    /// Fetches mode combinations.
    func fetchModeCombinations() {
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
                    let decodedData = try JSONDecoder().decode([ModeCombination].self, from: data)
                    DispatchQueue.main.async {
                        ModeManager.shared.modeCombinations = decodedData
                    }
                } catch {
                    OTPLog.log(level: .error, info: "Error decoding JSON: \(error.localizedDescription)")
                }
            }
        }.resume()
    }
}
