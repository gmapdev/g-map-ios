//
//  APIDataHelper.swift
//

import SwiftUI

struct DataFormatter {
    /// Convert.
    /// - Parameters:
    ///   - _: Parameter description
    /// - Returns: String
    /// Converts.
    static func convert(_ itineraries: Int) -> String {
        if itineraries == 1 {
            return "1 Trip Found".localized()
        }
        return "%1 Trips Found".localized(itineraries)
    }
}

extension Int {
    /// Walk speed display string.
    /// - Parameters:
    ///   - String: Parameter description
    var walkSpeedDisplayString: String {
        return String(self) + " MPH"
    }
}

extension String {
    /// Walk speed display string.
    /// - Parameters:
    ///   - String: Parameter description
    var walkSpeedDisplayString: String {
        return self + " MPH"
    }
    
    /// Max walk in meters.
    /// - Parameters:
    ///   - Int: Parameter description
    var maxWalkInMeters: Int {
        let components = self.components(separatedBy: "/").compactMap{ Double($0) }
        var result: Double = 1207 // meters = 3/4 miles
        let doubleValue = Double(self)
        if let walkMax = doubleValue {
            result = walkMax
        } else if !components.isEmpty,
                  let numerator = components.first,
                  let denominator = components.last {
            result = numerator / denominator
        }
        let maxWalk = Measurement(value: result, unit: UnitLength.miles)
        let meters = maxWalk.converted(to: .meters).value
        return Int(meters)
    }
    
    /// Max walk display string.
    /// - Parameters:
    ///   - String: Parameter description
    var maxWalkDisplayString: String {
        let components = self.components(separatedBy: "/").compactMap{ Int($0) }
        let intValue = Int(self)
        if let walkMax = intValue {
            return walkMax > 1 ? self + " miles" : self + " mile"
        } else if !components.isEmpty,
                  let numerator = components.first,
                  let denominator = components.last {
            return (numerator / denominator) > 1 ? self + " miles" : self + " mile"
        }
        return self
    }
    
    /// Remove ids
    /// Removes ids.
    func removeIds() {
        var idString: String? = nil
        for char in Array(self) {
            if idString == nil && char == "(" {
                idString = ""
            } else if idString != nil {
                
            }
        }
        
    }
}

