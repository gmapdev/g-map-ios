//
//  ParkRide.swift
//

import Foundation

struct ParkRide: Codable {
    let name: String
    let x: Double
    let y: Double
}

extension ParkRide {
    /// Coordinate.
    /// - Parameters:
    ///   - Coordinate: Parameter description
    var coordinate: Coordinate {
        Coordinate(lat: y, long: x)
    }
}
