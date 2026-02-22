//
//  Coordinate.swift
//

import Foundation

struct Coordinate: Hashable, Codable {
    let latitude: Double
    let longitude: Double
}

extension Coordinate {
    /// Lat:  double, long:  double
    /// Initializes a new instance.
    /// - Parameters:
    ///   - lat: Double
    ///   - long: Double
    init(lat: Double, long: Double) {
        self.latitude = lat
        self.longitude = long
    }
}
