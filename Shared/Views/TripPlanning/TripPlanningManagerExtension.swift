//
//  TripPlanningManagerExtension.swift
//

import Foundation

extension TripPlanningManager{

    /// Leg locations are equal.
    /// - Parameters:
    ///   - legLocationLat: Parameter description
    ///   - legLocationLon: Parameter description
    ///   - otherLat: Parameter description
    ///   - OtherLon: Parameter description
    /// - Returns: Bool
    func legLocationsAreEqual(legLocationLat: Double, legLocationLon: Double, otherLat: Double, OtherLon: Double) -> Bool{
        return legLocationLat == otherLat && legLocationLon == OtherLon
    }
    
    /// Difference in days.
    /// - Parameters:
    ///   - dateLeft: Parameter description
    ///   - dateRight: Parameter description
    /// - Returns: Int
    func differenceInDays(dateLeft: TimeInterval, dateRight: TimeInterval) -> Int {
        let calendar = Calendar.current
        
        let dateLeft = Date(timeIntervalSince1970: dateLeft)
        let dateRight = Date(timeIntervalSince1970: dateRight)
        
        let components = calendar.dateComponents([.day], from: dateLeft, to: dateRight)
        return components.day ?? 0
    }
}
